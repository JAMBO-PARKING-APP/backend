from celery import shared_task
from django.utils import timezone
from django.db.models import Sum, Count, Avg, Q
from datetime import timedelta
import logging

from apps.parking.models import Zone, ParkingSession
from apps.analytics.models import RevenueRecord
from apps.enforcement.models import Violation
from apps.common.constants import ParkingStatus

logger = logging.getLogger(__name__)

@shared_task
def generate_daily_revenue():
    """
    Calculate and store revenue statistics for the previous day.
    Runs daily just after midnight.
    Optimized to use DB-level aggregation.
    """
    today = timezone.now().date()
    yesterday = today - timedelta(days=1)
    
    logger.info(f"Generating revenue report for {yesterday}")
    sessions_qs = ParkingSession.objects.filter(
        actual_end_time__date=yesterday,
        status=ParkingStatus.COMPLETED
    ).values('zone').annotate(
        total_revenue=Sum('final_cost'),
        total_sessions=Count('id'),
    )
    
    violations_qs = Violation.objects.filter(
        created_at__date=yesterday
    ).values('zone').annotate(
        total_revenue=Sum('fine_amount', filter=Q(is_paid=True)),
        total_violations=Count('id')
    )
    
    sessions_data = {item['zone']: item for item in sessions_qs}
    violations_data = {item['zone']: item for item in violations_qs}
    all_zones = Zone.objects.filter(is_active=True)
    
    count = 0
    updates = []
    
    for zone in all_zones:
        s_data = sessions_data.get(zone.id, {})
        v_data = violations_data.get(zone.id, {})
        sess_rev = s_data.get('total_revenue') or 0
        sess_count = s_data.get('total_sessions') or 0
        avg_dur_mins = 0
        if sess_count > 0:
             pass

        viol_rev = v_data.get('total_revenue') or 0
        viol_count = v_data.get('total_violations') or 0
        
        total_rev = sess_rev + viol_rev
        
        updates.append(RevenueRecord(
            zone=zone,
            date=yesterday,
            total_revenue=total_rev,
            total_sessions=sess_count,
            total_violations=viol_count,
            average_duration_minutes=0 
        ))
        
    for rec in updates:
        RevenueRecord.objects.update_or_create(
            zone=rec.zone,
            date=rec.date,
            defaults={
                'total_revenue': rec.total_revenue,
                'total_sessions': rec.total_sessions,
                'total_violations': rec.total_violations,
                'average_duration_minutes': rec.average_duration_minutes
            }
        )
        count += 1
        
    return f"Generated revenue records for {count} zones for {yesterday}"
