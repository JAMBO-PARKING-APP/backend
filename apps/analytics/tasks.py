from celery import shared_task
from django.utils import timezone
from django.db.models import Sum, Count, Avg
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
    """
    # Calculate for "yesterday"
    today = timezone.now().date()
    yesterday = today - timedelta(days=1)
    
    logger.info(f"Generating revenue report for {yesterday}")
    
    zones = Zone.objects.filter(is_active=True)
    
    count = 0
    for zone in zones:
        # 1. Sessions ended yesterday
        sessions_qs = ParkingSession.objects.filter(
            zone=zone,
            actual_end_time__date=yesterday,
            status=ParkingStatus.COMPLETED
        )
        
        total_revenue_sessions = sessions_qs.aggregate(Sum('final_cost'))['final_cost__sum'] or 0
        total_sessions_count = sessions_qs.count()
        avg_duration = sessions_qs.aggregate(Avg('actual_end_time') - Avg('start_time'))
        
        # Calculate average duration in minutes
        avg_duration_mins = 0
        if total_sessions_count > 0:
            # This is complex in aggregation, let's do simple python loop if data is small, 
            # or rely on the Fact that django returns timedelta for diff.
            # But Avg of diff might be tricky.
            # Simplified:
            durations = [(s.actual_end_time - s.start_time).total_seconds() / 60 for s in sessions_qs if s.actual_end_time and s.start_time]
            if durations:
                avg_duration_mins = int(sum(durations) / len(durations))

        # 2. Violations issued yesterday
        violations_qs = Violation.objects.filter(
            zone=zone,
            created_at__date=yesterday
        )
        violations_revenue = violations_qs.filter(is_paid=True).aggregate(Sum('fine_amount'))['fine_amount__sum'] or 0
        violations_count = violations_qs.count()
        
        total_revenue = total_revenue_sessions + violations_revenue
        
        # Update or Create Record
        RevenueRecord.objects.update_or_create(
            zone=zone,
            date=yesterday,
            defaults={
                'total_revenue': total_revenue,
                'total_sessions': total_sessions_count,
                'total_violations': violations_count,
                'average_duration_minutes': avg_duration_mins
            }
        )
        count += 1
        
    return f"Generated revenue records for {count} zones for {yesterday}"
