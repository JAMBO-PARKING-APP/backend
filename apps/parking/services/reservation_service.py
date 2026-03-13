from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
import logging
from typing import Optional

from apps.parking.models import Zone, Reservation, ParkingSession, ParkingSlot
from apps.common.constants import ParkingStatus, SlotStatus, TransactionStatus
from apps.payments.models import WalletTransaction
from apps.notifications.notification_triggers import notify_reservation_confirmed, notify_reservation_cancelled

logger = logging.getLogger(__name__)

class ReservationService:
    @staticmethod
    def check_availability(zone: Zone, start_time: timezone.datetime, end_time: timezone.datetime) -> bool:
        """
        Check if there are available slots in the zone for the given time range.
        This is a complex check involving:
        1. Total capacity
        2. Existing confirmed reservations overlapping the period
        3. Active parking sessions overlapping the start period
        """
        total_capacity = zone.capacity
        if total_capacity <= 0:
            return False

        overlapping_reservations = Reservation.objects.filter(
            zone=zone,
            status__in=['confirmed', 'pending_payment'],
            reserved_from__lt=end_time,
            reserved_until__gt=start_time
        ).count()

        active_sessions = 0
        if start_time < timezone.now() + timedelta(hours=1):
             active_sessions = ParkingSession.objects.filter(
                zone=zone,
                status=ParkingStatus.ACTIVE
            ).count()

        available_slots = total_capacity - (overlapping_reservations + active_sessions)
        
        return available_slots > 0

    @staticmethod
    @transaction.atomic
    def create_reservation(
        vehicle, 
        zone: Zone, 
        start_time: timezone.datetime, 
        end_time: timezone.datetime,
        confirm_immediately: bool = False,
        payment_method: str = 'wallet'
    ) -> Reservation:
        """
        Create a reservation with concurrency locking.
        If confirm_immediately is True and payment_method is 'wallet', 
        it performs the payment and confirms the reservation atomically.
        """
        parking_slot = ParkingSlot.objects.filter(
            zone=zone,
            status=SlotStatus.AVAILABLE
        ).select_for_update(skip_locked=True).first()

        if not parking_slot:
            if not ReservationService.check_availability(zone, start_time, end_time):
                raise ValueError("No parking slots available for the selected time.")
            
            _ = Zone.objects.select_for_update().get(id=zone.id)

        duration_seconds = (end_time - start_time).total_seconds()
        duration_hours = Decimal(str(duration_seconds / 3600))
        if duration_hours < Decimal('0.25'):
            duration_hours = Decimal('0.25')
        
        cost = (duration_hours * zone.hourly_rate).quantize(Decimal('0.01'))

        reservation = Reservation.objects.create(
            vehicle=vehicle,
            zone=zone,
            parking_slot=parking_slot,
            reserved_from=start_time,
            reserved_until=end_time,
            cost=cost,
            status='pending_payment'
        )

        if parking_slot:
            parking_slot.status = SlotStatus.RESERVED 
            parking_slot.save()

        if confirm_immediately and payment_method == 'wallet':
            user = vehicle.user
            country = user.country
            
            from django.db.models import F
            if country:
                from apps.accounts.models import Wallet
                wallet, _ = Wallet.objects.get_or_create(user=user, country=country)
                wallet.balance = F('balance') - cost
                wallet.save(update_fields=['balance'])
            else:
                user.wallet_balance_legacy = F('wallet_balance_legacy') - cost
                user.save(update_fields=['wallet_balance_legacy'])
            
            WalletTransaction.objects.create(
                user=user,
                amount=cost,
                transaction_type='payment',
                status=TransactionStatus.COMPLETED,
                description=f"Immediate reservation for {zone.name}",
                metadata={'reservation_id': str(reservation.id)}
            )
            
            reservation.payment_reference = 'WALLET'
            reservation.status = 'confirmed'
            reservation.is_active = True
            reservation.save()
            
            notify_reservation_confirmed(reservation)
        else:
            from apps.parking.tasks import expire_reservation_task
            expire_reservation_task.apply_async((reservation.id,), countdown=900)

        return reservation

    @staticmethod
    @transaction.atomic
    def confirm_reservation(reservation: Reservation, payment_method='wallet') -> Reservation:
        if reservation.status != 'pending_payment':
            raise ValueError("Reservation is not pending payment")

        user = reservation.vehicle.user
        country = user.country

        if payment_method == 'wallet':
            from django.db.models import F
            if country:
                from apps.accounts.models import Wallet
                wallet, _ = Wallet.objects.get_or_create(user=user, country=country)
                wallet.balance = F('balance') - reservation.cost
                wallet.save(update_fields=['balance'])
            else:
                user.wallet_balance_legacy = F('wallet_balance_legacy') - reservation.cost
                user.save(update_fields=['wallet_balance_legacy'])
            
            WalletTransaction.objects.create(
                user=user,
                amount=reservation.cost,
                transaction_type='payment',
                status=TransactionStatus.COMPLETED,
                description=f"Reservation for {reservation.zone.name}",
                metadata={'reservation_id': str(reservation.id)}
            )
            
            reservation.payment_reference = 'WALLET'

        reservation.status = 'confirmed'
        reservation.is_active = True
        reservation.save()
        notify_reservation_confirmed(reservation)
        
        return reservation

    @staticmethod
    @transaction.atomic
    def cancel_reservation(reservation: Reservation) -> None:
        if reservation.status in ['cancelled', 'expired', 'completed']:
            return

        user = reservation.vehicle.user
        country = user.country

        if reservation.status == 'confirmed':
             refund_amount = reservation.cost
             
             if refund_amount > 0:
                 from django.db.models import F
                 if country:
                     from apps.accounts.models import Wallet
                     wallet, _ = Wallet.objects.get_or_create(user=user, country=country)
                     wallet.balance = F('balance') + refund_amount
                     wallet.save(update_fields=['balance'])
                 else:
                     user.wallet_balance_legacy = F('wallet_balance_legacy') + refund_amount
                     user.save(update_fields=['wallet_balance_legacy'])
                 
                 WalletTransaction.objects.create(
                    user=user,
                    amount=refund_amount,
                    transaction_type='refund',
                    status=TransactionStatus.COMPLETED,
                    description=f"Full refund for cancelled reservation {reservation.id}.",
                    metadata={
                        'reservation_id': str(reservation.id),
                        'original_cost': float(reservation.cost)
                    }
                )

        reservation.status = 'cancelled'
        reservation.is_active = False
        reservation.save()
        
        from apps.notifications.notification_triggers import notify_reservation_cancelled
        notify_reservation_cancelled(reservation)
