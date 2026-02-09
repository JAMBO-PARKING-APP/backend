from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from apps.parking.models import ParkingSession, ParkingStatus
from apps.notifications.models import NotificationEvent

class Command(BaseCommand):
    help = 'Sends alerts for sessions ending in 10 and 5 minutes'

    def handle(self, *args, **options):
        now = timezone.now()
        
        # 10 minute alerts
        ten_mins_later = now + timedelta(minutes=10)
        sessions_10 = ParkingSession.objects.filter(
            status=ParkingStatus.ACTIVE,
            planned_end_time__lte=ten_mins_later,
            planned_end_time__gt=now + timedelta(minutes=9)
        )
        
        for session in sessions_10:
            self._send_alert(session, 10)
            
        # 5 minute alerts
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
            session.status = ParkingStatus.EXPIRED
            session.save()
            self._send_alert(session, 0)

    def _send_alert(self, session, minutes_left):
        title = "Parking Session Alert"
        if minutes_left == 0:
            message = f"Your parking session in {session.zone.name} has finished."
            type = 'parking_ended'
        else:
            message = f"Your parking session in {session.zone.name} ends in {minutes_left} minutes."
            type = 'parking_ended' # We can use specialized types if needed
            
        # Check if already sent recently to avoid duplicates if run frequently
        existing = NotificationEvent.objects.filter(
            user=session.vehicle.user,
            type=type,
            title__contains=f"{minutes_left} minutes" if minutes_left > 0 else "finished",
            created_at__gt=timezone.now() - timedelta(minutes=2)
        ).exists()
        
        if not existing:
            NotificationEvent.objects.create(
                user=session.vehicle.user,
                title=title,
                message=message,
                type=type,
                category='parking',
                metadata={
                    'parking_session_id': str(session.id),
                    'minutes_left': minutes_left
                }
            )
            self.stdout.write(f"Sent {minutes_left}m alert to {session.vehicle.user.phone}")
