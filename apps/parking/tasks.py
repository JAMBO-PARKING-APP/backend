from celery import shared_task
from django.utils import timezone
from django.db.models import Q
from datetime import timedelta
import logging
from decimal import Decimal
import math

from apps.parking.models import ParkingSession, Reservation, Zone
from apps.accounts.models import User, UserLocation
from apps.notifications.firebase_service import send_notification_to_user
from apps.common.constants import ParkingStatus, SlotStatus

logger = logging.getLogger(__name__)

@shared_task
def check_expired_sessions():
    """
    Check for parking sessions that have exceeded their time.
    Marks them as EXPIRED, releases the slot, and notifies the user.
    """
    now = timezone.now()
    expired_sessions = ParkingSession.objects.filter(
        status=ParkingStatus.ACTIVE,
        planned_end_time__lt=now
    ).select_related('vehicle__user', 'zone')
    
    count = 0
    for session in expired_sessions.iterator(chunk_size=100):
        try:
            # End session formally (handles refunds, slot release, etc.)
            session.end_session()
            
            # Notify user
            user = session.vehicle.user
            send_notification_to_user(
                user,
                title="Parking Session Ended",
                body=f"Your parking session at {session.zone.name} has ended. Please vacate the premises immediately.",
                data={'type': 'session_ended', 'session_id': str(session.id)}
            )
            count += 1
            logger.info(f"Session {session.id} auto-ended and user notified.")
        except Exception as e:
            logger.error(f"Error auto-ending expired session {session.id}: {e}")

    return f"Auto-ended {count} expired sessions."

@shared_task
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
        if reservation.parking_slot:
            reservation.parking_slot.status = SlotStatus.AVAILABLE
            reservation.parking_slot.save()
        reservation.save()
        
    return f"Cancelled {count} overdue reservations."

@shared_task
def validate_active_session_location():
    """
    Check if users with active sessions are too far from the parking zone.
    Optimized to avoid N+1 queries.
    """
    # 1. Get all active sessions with related data
    active_sessions = ParkingSession.objects.filter(status=ParkingStatus.ACTIVE).select_related('vehicle__user', 'zone')
    
    if not active_sessions.exists():
        return "No active sessions to check."
        
    # 2. Extract User IDs to fetch locations in bulk
    user_ids = [session.vehicle.user.id for session in active_sessions]
    
    # 3. Fetch latest location for all these users in one query
    # We use a subquery or distinct on user with order_by to get latest.
    # Postgres 'DISTINCT ON' is perfect, but for DB agnostic (sqlite dev):
    # We can group by or just fetch all recent locations for these users and filter in python 
    # if the number of active sessions is reasonable (<1000).
    # Better: Use a Subquery annotation? 
    # For simplicity and 'Fast' enough:
    cutoff = timezone.now() - timedelta(minutes=20)
    recent_locations = UserLocation.objects.filter(
        user_id__in=user_ids, 
        timestamp__gte=cutoff
    ).order_by('user_id', '-timestamp')
    
    # Map user_id -> latest_location
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
            
        # Calculate distance
        dist_km = calculate_distance(
            float(last_location.latitude), float(last_location.longitude),
            float(zone.latitude), float(zone.longitude)
        )
        
        # If distance > 1.0 km (assuming they drove away)
        if dist_km > 1.0:
            send_notification_to_user(
                user,
                title="Active Parking Session",
                body=f"You seem to be away from {zone.name}. Did you forget to end your parking session?",
                data={'type': 'session_reminder', 'session_id': str(session.id)}
            )
            count += 1
            
    return f"Checked location for {len(active_sessions)} sessions. Sent {count} reminders."

@shared_task
def notify_exit_overdue():
    """
    Find users whose sessions recently ended (COMPLETED or EXPIRED) 
    but are still detected near the zone.
    """
    now = timezone.now()
    # Check sessions that ended in the last 20 minutes
    cutoff = now - timedelta(minutes=20)
    
    ended_sessions = ParkingSession.objects.filter(
        status__in=[ParkingStatus.COMPLETED, ParkingStatus.EXPIRED],
        updated_at__gte=cutoff
    ).select_related('vehicle__user', 'zone')
    
    if not ended_sessions.exists():
        return "No recently ended sessions to check."
        
    user_ids = [s.vehicle.user.id for s in ended_sessions]
    
    # Get latest location for these users
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
        
        # If still within 200m of the zone (roughly radius_meters)
        # Assuming radius_meters is around 100m, 200m is a safe 'still there' check
        if dist_km < 0.2:
            send_notification_to_user(
                user,
                title="Exit Reminder",
                body=f"Your session at {zone.name} has ended. Please remember to exit the zone to avoid penalties.",
                data={'type': 'exit_reminder', 'session_id': str(session.id)}
            )
            count += 1
            
    return f"Sent exit reminders to {count} users."

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees)
    """
    # Convert decimal degrees to radians 
    lon1, lat1, lon2, lat2 = map(math.radians, [lon1, lat1, lon2, lat2])

    # Haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a)) 
    r = 6371 # Radius of earth in kilometers
    return c * r
