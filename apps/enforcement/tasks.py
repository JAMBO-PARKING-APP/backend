from celery import shared_task
from django.utils import timezone
from django.db.models import Count, Q
from datetime import timedelta
import logging

from apps.parking.models import ParkingSession, Zone
from apps.enforcement.models import OfficerStatus
from apps.notifications.firebase_service import send_notification_to_user
from apps.common.constants import ParkingStatus

logger = logging.getLogger(__name__)

@shared_task
def identify_violation_hotspots():
    """
    Identify zones with high number of likely violations (expired sessions)
    and alert nearby officers.
    """
    now = timezone.now()
    # Expired more than 15 minutes ago
    cutoff_time = now - timedelta(minutes=15)
    
    # 1. Find zones with high number of expired sessions
    # We count active sessions that started but expired long ago
    hotspot_zones = ParkingSession.objects.filter(
        status=ParkingStatus.ACTIVE,
        planned_end_time__lt=cutoff_time
    ).values('zone').annotate(expired_count=Count('id')).filter(expired_count__gte=3)
    
    # 2. Iterate and alert officers
    alert_count = 0
    for hotspot in hotspot_zones:
        zone_id = hotspot['zone']
        count = hotspot['expired_count']
        
        try:
            zone = Zone.objects.get(id=zone_id)
            
            # Find online officers
            # Ideally sort by distance, but for now just any online officer
            # or officer assigned to this zone?
            # Let's alert any online officer assigned to this zone or free-roaming
            
            # Simple logic: Alert all online officers who are NOT already in a violation hotspot
            # For MVP: Alert all online officers about the hotspot
            online_officers_status = OfficerStatus.objects.filter(is_online=True)
            
            for status in online_officers_status:
                officer = status.officer
                # Send notification
                send_notification_to_user(
                    officer,
                    title="Violation Hotspot Detected",
                    body=f"High violation activity in {zone.name} ({count} potential violations). Please patrol.",
                    data={'type': 'officer_dispatch', 'zone_id': str(zone.id)}
                )
                alert_count += 1
                
        except Zone.DoesNotExist:
            continue
            
    return f"Identified {len(hotspot_zones)} hotspots. Sent {alert_count} alerts."
