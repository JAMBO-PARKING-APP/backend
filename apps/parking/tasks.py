from celery import shared_task
from django.utils import timezone
from django.db.models import Q
from datetime import timedelta
import logging
from decimal import Decimal
import math

from django.core.cache import caches
from apps.parking.models import ParkingSession, Reservation, Zone, ParkingSlot
from apps.accounts.models import User, UserLocation
from apps.common.constants import ParkingStatus, SlotStatus

logger = logging.getLogger(__name__)

@shared_task(name='apps.parking.tasks.check_expired_sessions')
def check_expired_sessions():
    """
    Check for parking sessions that have exceeded their time.
    Calculates overdue charges and notifies the user.
    """
    now = timezone.now()
    expired_sessions = ParkingSession.objects.filter(
        status=ParkingStatus.ACTIVE,
        planned_end_time__lt=now
    ).select_related('vehicle__user', 'zone')
    
    count = 0
    for session in expired_sessions.iterator(chunk_size=100):
        try:
            user = session.vehicle.user
            planned_end = session.planned_end_time
            
            session.end_session()
            count += 1
            logger.info(f"Session {session.id} auto-ended and charged.")
        except Exception as e:
            logger.error(f"Error auto-ending expired session {session.id}: {e}")

    return f"Processed {count} expired sessions."

@shared_task(name='apps.parking.tasks.send_session_alerts')
def send_session_alerts():
    """
    Periodic task to send alerts for sessions ending in 10 and 5 minutes.
    """
    now = timezone.now()
    from apps.notifications.notification_triggers import notify_parking_expiring_soon
    from apps.notifications.models import NotificationEvent
    
    ten_mins_later = now + timedelta(minutes=10)
    sessions_10 = ParkingSession.objects.filter(
        status=ParkingStatus.ACTIVE,
        planned_end_time__lte=ten_mins_later,
        planned_end_time__gt=now + timedelta(minutes=9)
    )
    
    for session in sessions_10:
        if not NotificationEvent.objects.filter(
            user=session.vehicle.user,
            type='parking_expiring',
            metadata__session_id=str(session.id),
            metadata__minutes_remaining=10,
            created_at__gt=now - timedelta(minutes=2)
        ).exists():
            notify_parking_expiring_soon(session, 10)
            
    five_mins_later = now + timedelta(minutes=5)
    sessions_5 = ParkingSession.objects.filter(
        status=ParkingStatus.ACTIVE,
        planned_end_time__lte=five_mins_later,
        planned_end_time__gt=now + timedelta(minutes=4)
    )
    
    for session in sessions_5:
        if not NotificationEvent.objects.filter(
            user=session.vehicle.user,
            type='parking_expiring',
            metadata__session_id=str(session.id),
            metadata__minutes_remaining=5,
            created_at__gt=now - timedelta(minutes=2)
        ).exists():
            notify_parking_expiring_soon(session, 5)

    return "Sent session alerts."

@shared_task(name='apps.parking.tasks.cancel_overdue_reservations')
def cancel_overdue_reservations():
    """
    Cancel reservations that are pending payment for more than 15 minutes.
    """
    now = timezone.now()
    cutoff_time = now - timedelta(minutes=15)
    
    overdue_reservations = Reservation.objects.filter(
        status='pending_payment',
        created_at__lt=cutoff_time
    )
    
    count = overdue_reservations.count()
    for reservation in overdue_reservations:
        reservation.status = 'cancelled'
        reservation.save()
        
        from apps.notifications.notification_triggers import notify_reservation_cancelled
        notify_reservation_cancelled(reservation)
        
    return f"Cancelled {count} overdue reservations."

@shared_task(name='apps.parking.tasks.check_reservation_attendance')
def check_reservation_attendance(reservation_id):
    """
    Check if a user has arrived for their reservation within 30 minutes of start.
    If not, the reservation is marked as expired and no refund is issued.
    """
    try:
        reservation = Reservation.objects.get(id=reservation_id, status='confirmed')
        
        # Check if there is an active session for this vehicle in this zone
        session_exists = ParkingSession.objects.filter(
            vehicle=reservation.vehicle,
            zone=reservation.zone,
            status=ParkingStatus.ACTIVE,
            start_time__gte=reservation.reserved_from - timedelta(minutes=10) # Buffer
        ).exists()
        
        if session_exists:
            return f"Reservation {reservation_id} validated: User arrived."

        # Check location if no session
        user = reservation.vehicle.user
        last_loc = UserLocation.objects.filter(user=user).order_by('-timestamp').first()
        
        arrived = False
        if last_loc:
            dist_km = calculate_distance(
                float(last_loc.latitude), float(last_loc.longitude),
                float(reservation.zone.latitude), float(reservation.zone.longitude)
            )
            if dist_km < 0.2: # 200 meters
                arrived = True
        
        if not arrived:
            # Mark as expired, no refund logic needed here as it simply stops being 'confirmed'
            reservation.status = 'expired'
            reservation.is_active = False
            reservation.save()
            
            from apps.notifications.notification_triggers import notify_reservation_cancelled
            # You might want a specific 'expired_no_show' notification
            notify_reservation_cancelled(reservation)
            return f"Reservation {reservation_id} expired: No-show after 30 mins."
            
        return f"Reservation {reservation_id} pending: User is in zone but hasn't started session."
        
    except Reservation.DoesNotExist:
        return f"Reservation {reservation_id} not found or not confirmed."

@shared_task
def expire_reservation_task(reservation_id):
    """
    Check if a reservation is still 'pending_payment' after the timeout.
    If so, mark as expired and release the slot.
    """
    try:
        reservation = Reservation.objects.get(id=reservation_id)
        if reservation.status == 'pending_payment':
            reservation.status = 'expired'
            reservation.save()
            logger.info(f"Reservation {reservation_id} expired automatically.")
            
            from apps.notifications.notification_triggers import notify_reservation_cancelled
            notify_reservation_cancelled(reservation)
            return f"Reservation {reservation_id} expired."
        return f"Reservation {reservation_id} state was {reservation.status}, no action taken."
    except Reservation.DoesNotExist:
        logger.warning(f"Task for non-existent reservation {reservation_id}")
        return f"Reservation {reservation_id} not found."

@shared_task(name='apps.parking.tasks.validate_active_session_location')
def validate_active_session_location():
    """
    Check if users with active sessions are too far from the parking zone.
    Optimized to avoid N+1 queries.
    """
    active_sessions = ParkingSession.objects.filter(status=ParkingStatus.ACTIVE).select_related('vehicle__user', 'zone')
    
    if not active_sessions.exists():
        return "No active sessions to check."
        
    user_ids = [session.vehicle.user.id for session in active_sessions]
    
    cutoff = timezone.now() - timedelta(minutes=20)
    recent_locations = UserLocation.objects.filter(
        user_id__in=user_ids, 
        timestamp__gte=cutoff
    ).order_by('user_id', '-timestamp')
    
    user_locations = {}
    for loc in recent_locations:
        if loc.user_id not in user_locations:
            user_locations[loc.user_id] = loc
            
    count = 0
    
    for session in active_sessions:
        user = session.vehicle.user
        zone = session.zone
        
        last_location = user_locations.get(user.id)
        
        if not last_location:
            continue
            
        dist_km = calculate_distance(
            float(last_location.latitude), float(last_location.longitude),
            float(zone.latitude), float(zone.longitude)
        )
        
        if dist_km > 1.0:
            from apps.notifications.notification_triggers import notify_session_reminder
            notify_session_reminder(session)
            count += 1
            
    return f"Checked location for {len(active_sessions)} sessions. Sent {count} reminders."

@shared_task(name='apps.parking.tasks.notify_exit_overdue')
def notify_exit_overdue():
    """
    Find users whose sessions recently ended (COMPLETED or EXPIRED) 
    but are still detected near the zone.
    """
    now = timezone.now()

    cutoff = now - timedelta(minutes=20)
    
    ended_sessions = ParkingSession.objects.filter(
        status__in=[ParkingStatus.COMPLETED, ParkingStatus.EXPIRED],
        updated_at__gte=cutoff
    ).select_related('vehicle__user', 'zone')
    
    if not ended_sessions.exists():
        return "No recently ended sessions to check."
        
    user_ids = [s.vehicle.user.id for s in ended_sessions]
    
    recent_locations = UserLocation.objects.filter(
        user_id__in=user_ids, 
        timestamp__gte=cutoff
    ).order_by('user_id', '-timestamp')
    
    user_locations = {}
    for loc in recent_locations:
        if loc.user_id not in user_locations:
            user_locations[loc.user_id] = loc
            
    count = 0
    for session in ended_sessions:
        user = session.vehicle.user
        zone = session.zone
        last_loc = user_locations.get(user.id)
        
        if not last_loc:
            continue
            
        dist_km = calculate_distance(
            float(last_loc.latitude), float(last_loc.longitude),
            float(zone.latitude), float(zone.longitude)
        )
        
        if dist_km < 0.2:
            from apps.notifications.notification_triggers import notify_exit_reminder
            notify_exit_reminder(session)
            count += 1
            
    return f"Sent exit reminders to {count} users."

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees)
    """

    lon1, lat1, lon2, lat2 = map(math.radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a)) 
    r = 6371 
    return c * r

@shared_task(name='apps.parking.tasks.update_zone_availability_cache')
def update_zone_availability_cache():
    """
    Performance task: Pre-calculate availability for all zones and store in Redis.
    This makes the home screen/zone list extremely fast.
    """
    from apps.parking.serializers_v2 import ZoneListSerializer
    from django.db.models import Count, Q, Case, When, F, Value
    
    zones = Zone.objects.filter(is_active=True).annotate(
        annotated_active_sessions=Count(
            'sessions', 
            filter=Q(sessions__status=ParkingStatus.ACTIVE),
            distinct=True
        ),
        annotated_capacity=Case(
            When(total_slots__gt=0, then=F('total_slots')),
            default=Count('slots', distinct=True),
        )
    ).annotate(
        annotated_available_slots=Case(
            When(annotated_capacity__gt=F('annotated_active_sessions'), 
                 then=F('annotated_capacity') - F('annotated_active_sessions')),
            default=Value(0),
        )
    )
    
    cache = caches['zones_cache']
    count = 0
    for zone in zones:
        serializer = ZoneListSerializer(zone)
        cache.set(f"zone_stats_{zone.id}", serializer.data, timeout=3600)
        count += 1
        
    logger.info(f"Updated cache for {count} zones.")
    return f"Cached {count} zones."

@shared_task(name='apps.parking.tasks.cleanup_slot_statuses')
def cleanup_slot_statuses():
    """
    Autonomy task: A self-healing watchdog that resets 'stuck' slots.
    If a slot is RESERVED/OCCUPIED but has no active session/reservation, reset it.
    """
    cutoff = timezone.now() - timedelta(minutes=20)
    stuck_reserved = ParkingSlot.objects.filter(
        status=SlotStatus.RESERVED,
        modified_at__lt=cutoff
    )
    
    reset_count = 0
    for slot in stuck_reserved:
        if not Reservation.objects.filter(
            parking_slot=slot, 
            status__in=['pending_payment', 'confirmed'],
            is_active=True
        ).exists():
            slot.status = SlotStatus.AVAILABLE
            slot.save()
            reset_count += 1
            
    stuck_occupied = ParkingSlot.objects.filter(status=SlotStatus.OCCUPIED)
    for slot in stuck_occupied:
        if not ParkingSession.objects.filter(
            parking_slot=slot,
            status=ParkingStatus.ACTIVE
        ).exists():
            slot.status = SlotStatus.AVAILABLE
            slot.save()
            reset_count += 1
            
    if reset_count > 0:
        logger.warning(f"Watchdog reset {reset_count} stuck slots.")
    return f"Reset {reset_count} stuck slots."
