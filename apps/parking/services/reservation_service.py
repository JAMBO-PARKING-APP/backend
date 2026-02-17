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

        # 1. Count overlapping confirmed/pending reservations
        overlapping_reservations = Reservation.objects.filter(
            zone=zone,
            status__in=['confirmed', 'pending_payment'],
            reserved_from__lt=end_time,
            reserved_until__gt=start_time
        ).count()

        # 2. Count active sessions (only if start_time is "now" or very soon)
        # For future bookings, we assume current sessions will end, unless they are long-term? 
        # For simplicity in this MVP: 
        # If booking is for NOW, we check active sessions.
        # If booking is for FUTURE, we mostly rely on reservations. 
        # A more robust system would track "estimated end time" of active sessions.
        
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
        end_time: timezone.datetime
    ) -> Reservation:
        """
        Create a reservation with concurrency locking.
        """
        # Lock an available slot for update instead of the entire zone
        # This allows multiple users to book different slots in the same zone concurrently.
        parking_slot = ParkingSlot.objects.filter(
            zone=zone,
            status=SlotStatus.AVAILABLE
        ).select_for_update(skip_locked=True).first()

        if not parking_slot:
            # Fallback check: if we explicitly track slots, but none are available
            # Or if we rely on capacity, check if the calculated availability is > 0
            if not ReservationService.check_availability(zone, start_time, end_time):
                raise ValueError("No parking slots available for the selected time.")
            
            # If availability check passed but no specific slot was found, 
            # it might be a zone without pre-defined slots (using capacity only).
            # In that case, we still need a lock. We'll use the zone lock as fallback
            # but ideally, all zones should have defined slots for high scalability.
            _ = Zone.objects.select_for_update().get(id=zone.id)

        # Calculate cost
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

        # Mark slot as reserved if we found one
        if parking_slot:
            parking_slot.status = SlotStatus.RESERVED  # Need to ensure SlotStatus.RESERVED exists or use OCCUPIED
            parking_slot.save()
        
        # Schedule expiration task
        from apps.parking.tasks import expire_reservation_task
        # Schedules task to run after 15 minutes
        expire_reservation_task.apply_async((reservation.id,), countdown=900)

        return reservation

    @staticmethod
    @transaction.atomic
    def confirm_reservation(reservation: Reservation, payment_method='wallet') -> Reservation:
        if reservation.status != 'pending_payment':
            raise ValueError("Reservation is not pending payment")

        user = reservation.vehicle.user
        
        if payment_method == 'wallet':
            from django.db.models import F
            user.wallet_balance = F('wallet_balance') - reservation.cost
            user.save(update_fields=['wallet_balance'])
            
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
        
        # Notify user
        notify_reservation_confirmed(reservation)
        
        return reservation

    @staticmethod
    def cancel_reservation(reservation: Reservation) -> None:
        if reservation.status in ['cancelled', 'expired', 'completed']:
            return

        # If confirmed and start time hasn't passed (or with penalty), refund?
        # For MVP: Full refund if cancelled before start time
        if reservation.status == 'confirmed':
             if timezone.now() < reservation.reserved_from:
                 # Refund logic
                 from django.db.models import F
                 user.wallet_balance = F('wallet_balance') + reservation.cost
                 user.save(update_fields=['wallet_balance'])
                 
                 WalletTransaction.objects.create(
                    user=user,
                    amount=reservation.cost,
                    transaction_type='refund',
                    status=TransactionStatus.COMPLETED,
                    description=f"Refund for reservation cancellation {reservation.id}",
                    metadata={'reservation_id': str(reservation.id)}
                )

        reservation.status = 'cancelled'
        reservation.is_active = False
        reservation.save()
        
        notify_reservation_cancelled(reservation)
