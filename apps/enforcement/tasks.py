from celery import shared_task
from django.utils import timezone
from django.db.models import Count, Q
from datetime import timedelta
import logging

from apps.parking.models import ParkingSession, Zone
from apps.enforcement.models import OfficerStatus
from apps.common.constants import ParkingStatus

logger = logging.getLogger(__name__)

@shared_task
def identify_violation_hotspots():
    """
    Identify zones with high number of likely violations (expired sessions)
    and alert nearby officers.
    """
    now = timezone.now()
    cutoff_time = now - timedelta(minutes=15)
    hotspot_zones = ParkingSession.objects.filter(
        status=ParkingStatus.ACTIVE,
        planned_end_time__lt=cutoff_time
    ).values('zone').annotate(expired_count=Count('id')).filter(expired_count__gte=3)
    
    alert_count = 0
    for hotspot in hotspot_zones:
        zone_id = hotspot['zone']
        count = hotspot['expired_count']
        
        try:
            zone = Zone.objects.get(id=zone_id)
            
            online_officers_status = OfficerStatus.objects.filter(is_online=True)
            
            for status in online_officers_status:
                officer = status.officer
                from apps.notifications.notification_triggers import notify_hotspot_detected
                notify_hotspot_detected(officer, zone, count)
                alert_count += 1
                
        except Zone.DoesNotExist:
            continue
            
    return f"Identified {len(hotspot_zones)} hotspots. Sent {alert_count} alerts."

@shared_task(name='apps.enforcement.tasks.escalate_unpaid_violations')
def escalate_unpaid_violations():
    """
    Autonomy task: Automatically increase fines for unpaid violations after 48 hours.
    Fines increase by 10% daily.
    """
    from .models import Violation
    from decimal import Decimal
    
    cutoff_time = timezone.now() - timedelta(hours=48)
    unpaid_violations = Violation.objects.filter(
        is_paid=False,
        created_at__lt=cutoff_time
    )
    
    count = 0
    total_increase = Decimal('0')
    
    for violation in unpaid_violations:
        old_fine = violation.fine_amount
        increase = (old_fine * Decimal('0.10')).quantize(Decimal('0.01'))
        violation.fine_amount += increase
        violation.save()
        
        total_increase += increase
        count += 1
        
        from apps.notifications.notification_triggers import notify_violation_escalation
        notify_violation_escalation(violation, increase)
        
    if count > 0:
        logger.info(f"Escalated {count} violations. Total fine increase: {total_increase}")
    return f"Escalated {count} violations."
