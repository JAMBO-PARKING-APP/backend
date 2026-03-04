from celery import shared_task
from django.utils import timezone
from datetime import timedelta
import logging
import shutil
from django.db import connection
from django.core.cache import cache
from django.conf import settings
from apps.accounts.models import User, UserLocation
from apps.notifications.models import NotificationEvent
from apps.enforcement.models import OfficerLog, QRCodeScan

logger = logging.getLogger(__name__)

@shared_task
def cleanup_system_data():
    """
    Autonomous maintenance task to clean up old data and optimize storage.
    Run weekly or daily.
    """
    now = timezone.now()
    results = {}
    loc_cutoff = now - timedelta(days=7)
    deleted_loc, _ = UserLocation.objects.filter(timestamp__lt=loc_cutoff).delete()
    results['user_location_deleted'] = deleted_loc
    notif_cutoff = now - timedelta(days=30)
    deleted_notif, _ = NotificationEvent.objects.filter(
        created_at__lt=notif_cutoff,
        is_read=True
    ).delete()
    results['notifications_deleted'] = deleted_notif
    audit_cutoff = now - timedelta(days=90)
    deleted_logs, _ = OfficerLog.objects.filter(created_at__lt=audit_cutoff).delete()
    results['officer_logs_deleted'] = deleted_logs
    deleted_scans, _ = QRCodeScan.objects.filter(created_at__lt=audit_cutoff).delete()
    results['qr_scans_deleted'] = deleted_scans
    deleted_users, _ = User.objects.filter(
        is_active=False,
        deletion_planned_at__lte=now
    ).delete()
    results['permanent_user_deletions'] = deleted_users
    
    logger.info(f"System Cleanup Completed: {results}")
    return f"Cleanup finished: {results}"

@shared_task
def check_system_health():
    """
    Periodic health check task to verify system components.
    """
    health_status = {
        'database': False,
        'redis': False,
        'disk_usage': 0,
        'status': 'healthy'
    }
    
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            row = cursor.fetchone()
            if row and row[0] == 1:
                health_status['database'] = True
    except Exception as e:
        logger.critical(f"Health Check - Database Failed: {e}")
        health_status['status'] = 'critical'
        
    try:
        cache.set('health_check', 'ok', timeout=10)
        if cache.get('health_check') == 'ok':
            health_status['redis'] = True
    except Exception as e:
        logger.error(f"Health Check - Redis Failed: {e}")
        if health_status['status'] != 'critical':
             health_status['status'] = 'degraded'

    try:
        total, used, free = shutil.disk_usage(settings.BASE_DIR)
        percent_used = (used / total) * 100
        health_status['disk_usage'] = round(percent_used, 2)
        
        if percent_used > 90:
            logger.warning(f"Health Check - High Disk Usage: {percent_used}%")
            if health_status['status'] == 'healthy':
                health_status['status'] = 'warning'
    except Exception as e:
         logger.error(f"Health Check - Disk Check Failed: {e}")
         
    if health_status['status'] != 'healthy':
        logger.warning(f"System Health Issue Detected: {health_status}")
    else:
        logger.info(f"System Health Check Passed: {health_status}")
        
    return health_status
