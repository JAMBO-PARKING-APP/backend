from celery import shared_task
from django.utils import timezone
from datetime import timedelta
import logging
import shutil
from django.db import connection
from django.core.cache import cache
from django.conf import settings

# Import models dynamically to avoid circular imports if any, 
# but usually models are safe in tasks.
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
    
    # 1. Cleanup User Location History (> 7 days)
    # Location data grows very fast.
    loc_cutoff = now - timedelta(days=7)
    # Use _raw_delete or filter().delete()
    # For massive tables, deleting in chunks is better, but filter().delete() is usually optimized by DB 
    # unless it cascades too much. UserLocation cascades nothing.
    deleted_loc, _ = UserLocation.objects.filter(timestamp__lt=loc_cutoff).delete()
    results['user_location_deleted'] = deleted_loc
    
    # 2. Cleanup Read Notifications (> 30 days)
    notif_cutoff = now - timedelta(days=30)
    deleted_notif, _ = NotificationEvent.objects.filter(
        created_at__lt=notif_cutoff,
        is_read=True
    ).delete()
    results['notifications_deleted'] = deleted_notif
    
    # 3. Cleanup Officer Logs (> 90 days)
    # Audit logs should be kept longer.
    audit_cutoff = now - timedelta(days=90)
    deleted_logs, _ = OfficerLog.objects.filter(created_at__lt=audit_cutoff).delete()
    results['officer_logs_deleted'] = deleted_logs
    
    # 4. Cleanup QR Scans (> 90 days)
    deleted_scans, _ = QRCodeScan.objects.filter(created_at__lt=audit_cutoff).delete()
    results['qr_scans_deleted'] = deleted_scans

    # 5. Permanent Account Deletion
    # Delete users whose planned deletion date has passed
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
    
    # 1. Check Database
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            row = cursor.fetchone()
            if row and row[0] == 1:
                health_status['database'] = True
    except Exception as e:
        logger.critical(f"Health Check - Database Failed: {e}")
        health_status['status'] = 'critical'
        
    # 2. Check Redis (Cache)
    try:
        cache.set('health_check', 'ok', timeout=10)
        if cache.get('health_check') == 'ok':
            health_status['redis'] = True
    except Exception as e:
        logger.error(f"Health Check - Redis Failed: {e}")
        if health_status['status'] != 'critical':
             health_status['status'] = 'degraded'

    # 3. Check Disk Usage
    # Check the disk where settings.BASE_DIR is located
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
        # Here we could send an admin email alert if critical
        logger.warning(f"System Health Issue Detected: {health_status}")
    else:
        logger.info(f"System Health Check Passed: {health_status}")
        
    return health_status
