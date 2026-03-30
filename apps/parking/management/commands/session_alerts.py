from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from apps.parking.models import ParkingSession, ParkingStatus, ParkingSlot, Zone
from apps.common.constants import SlotStatus
from apps.notifications.models import NotificationEvent
from apps.payments.models import WalletTransaction
from apps.enforcement.models import Violation
from apps.common.constants import ViolationType

class Command(BaseCommand):
    help = 'Sends alerts for sessions ending in 10 and 5 minutes, and handles expired sessions with charges'

    def handle(self, *args, **options):
        now = timezone.now()
        ten_mins_later = now + timedelta(minutes=10)
        sessions_10 = ParkingSession.objects.filter(
            status=ParkingStatus.ACTIVE,
            planned_end_time__lte=ten_mins_later,
            planned_end_time__gt=now + timedelta(minutes=9)
        )
        
        for session in sessions_10:
            self._send_alert(session, 10)
        five_mins_later = now + timedelta(minutes=5)
        sessions_5 = ParkingSession.objects.filter(
            status=ParkingStatus.ACTIVE,
            planned_end_time__lte=five_mins_later,
            planned_end_time__gt=now + timedelta(minutes=4)
        )
        
        for session in sessions_5:
            self._send_alert(session, 5)
            
        # Sessions that just expired
        expired_sessions = ParkingSession.objects.filter(
            status=ParkingStatus.ACTIVE,
            planned_end_time__lte=now
        )
        
        for session in expired_sessions:
            self._handle_expired_session(session, now)

    def _send_alert(self, session, minutes_left):
        title = "Parking Session Alert"
        if minutes_left == 0:
            message = f"Your parking session in {session.zone.name} has finished."
            type = 'parking_ended'
        else:
            message = f"Your parking session in {session.zone.name} ends in {minutes_left} minutes."
            type = 'parking_ended' 
            
        existing = NotificationEvent.objects.filter(
            user=session.vehicle.user,
            type=type,
            title__contains=f"{minutes_left} minutes" if minutes_left > 0 else "finished",
            created_at__gt=timezone.now() - timedelta(minutes=2)
        ).exists()
        
        if not existing:
            from apps.notifications.notification_triggers import notify_parking_expiring_soon
            notify_parking_expiring_soon(session, minutes_left)
            self.stdout.write(f"Sent {minutes_left}m alert to {session.vehicle.user.phone}")

    def _handle_expired_session(self, session, now):
        """
        Handle expired parking sessions:
        1. Send notification that session has ended
        2. Calculate overdue time and charge extra
        3. Deduct from wallet or create violation if insufficient balance
        """
        user = session.vehicle.user
        session.actual_end_time = now
        actual_cost = session.calculate_cost()
        planned_seconds = (session.planned_end_time - session.start_time).total_seconds()
        duration_seconds = (now - session.start_time).total_seconds()
        overdue_seconds = max(0, duration_seconds - planned_seconds)
        overdue_hours = Decimal(str(overdue_seconds / 3600))
        overdue_charge = (overdue_hours * session.zone.hourly_rate).quantize(Decimal('0.01'))
        session.final_cost = actual_cost
        session.status = ParkingStatus.EXPIRED
        
        if session.parking_slot:
            session.parking_slot.status = SlotStatus.AVAILABLE
            session.parking_slot.save()
        
        session.save()
        
        from apps.notifications.notification_triggers import notify_parking_ended
        notify_parking_ended(session)
        
        if overdue_charge > 0:
            wallet_balance = user.wallet_balance
            
            if wallet_balance >= overdue_charge:
                user.wallet_balance -= overdue_charge
                user.save()
                WalletTransaction.objects.create(
                    user=user,
                    amount=overdue_charge,
                    transaction_type='payment',
                    status='completed',
                    description=f'Overdue parking charge for {session.zone.name} - {overdue_hours:.2f} hours',
                    parking_session=session
                )
                from apps.notifications.notification_triggers import notify_overdue_charge
                notify_overdue_charge(user, overdue_charge, overdue_hours, session.id)
                
                self.stdout.write(
                    f"✓ Charged {user.phone} UGX {overdue_charge} for {overdue_hours:.2f}h overdue"
                )
            else:
                violation_fine = overdue_charge  
                user.wallet_balance -= overdue_charge  
                user.save()
                
                violation = Violation.objects.create(
                    vehicle=session.vehicle,
                    officer=None,   
                    zone=session.zone,
                    parking_session=session,
                    violation_type=ViolationType.OVERDUE_PARKING,
                    description=f'Vehicle parked {overdue_hours:.2f} hours beyond planned end time without payment',
                    fine_amount=violation_fine,
                    latitude=session.zone.latitude,
                    longitude=session.zone.longitude
                )
                
                WalletTransaction.objects.create(
                    user=user,
                    amount=overdue_charge,
                    transaction_type='payment',
                    status='completed',
                    description=f'Overdue parking charge for {session.zone.name} - {overdue_hours:.2f} hours',
                    parking_session=session
                )
                
                from apps.notifications.notification_triggers import notify_violation_issued
                v_message = f"A violation has been issued for {overdue_hours:.2f} hours of unpaid overdue parking at {session.zone.name}. Fine: UGX {violation_fine}. Your wallet balance is now UGX {user.wallet_balance}"
                notify_violation_issued(violation, message=v_message)
                
                self.stdout.write(
                    f"✗ Violation created for {user.phone}: {overdue_hours:.2f}h overdue, fine UGX {violation_fine}, balance: UGX {user.wallet_balance}"
                )
