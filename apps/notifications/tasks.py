from celery import shared_task
from django.contrib.auth import get_user_model
from . import firebase_service, twilio_service
import logging

logger = logging.getLogger(__name__)
User = get_user_model()

def _run_async_safe(func, *args, **kwargs):
    """Helper to run a function in a way that handles Django's async-safety checks"""
    import os
    os.environ["DJANGO_ALLOW_ASYNC_UNSAFE"] = "true"
    try:
        return func(*args, **kwargs)
    finally:
        pass

@shared_task
def send_firebase_notification_task(user_id, title, body, data=None, notification_event_id=None):
    """
    Async task to send Firebase notification to a user.
    """
    from asgiref.sync import async_to_sync
    
    def _do_send():
        try:
            user = User.objects.get(id=user_id)
            
            notification_event = None
            if notification_event_id:
                from .models import NotificationEvent
                try:
                    notification_event = NotificationEvent.objects.get(id=notification_event_id)
                except NotificationEvent.DoesNotExist:
                    logger.warning(f"NotificationEvent {notification_event_id} not found in task")
            
            firebase_service.send_notification_to_user_sync(user, title, body, data, notification_event)
            
        except User.DoesNotExist:
            logger.error(f"User {user_id} not found for notification task")
        except Exception as e:
            logger.error(f"Error in send_firebase_notification_task logic: {e}")
            raise e

    try:
        _run_async_safe(_do_send)
    except Exception as e:
        logger.error(f"Error in send_firebase_notification_task: {e}")

@shared_task
def send_twilio_verification_task(to_phone, channel='sms'):
    """
    Async task to send Twilio verification.
    """
    try:
        _run_async_safe(twilio_service.send_verification_sync, to_phone, channel)
    except Exception as e:
        logger.error(f"Error in send_twilio_verification_task: {e}")

@shared_task
def send_multicast_notification_task(user_ids, title, body, data=None):
    """
    Batch send notifications to multiple users in a single FCM request.
    """
    def _do_multicast():
        try:
            users = User.objects.filter(id__in=user_ids, fcm_device_token__isnull=False)
            if not users.exists():
                return "No users with tokens to notify"
                
            return firebase_service.send_multicast_sync(users, title, body, data)
        except Exception as e:
            logger.error(f"Error in multicast logic: {e}")
            raise e

    try:
        return _run_async_safe(_do_multicast)
    except Exception as e:
        logger.error(f"Error in send_multicast_notification_task: {e}")
        return False

@shared_task
def broadcast_websocket_update_task(user_id, data):
    """
    Async task to broadcast WebSocket update to a user.
    """
    from asgiref.sync import async_to_sync
    from channels.layers import get_channel_layer
    
    channel_layer = get_channel_layer()
    user_group_name = f"user_{user_id}".replace("-", "_")
    
    try:
        async_to_sync(channel_layer.group_send)(
            user_group_name,
            {
                'type': 'parking_update',
                'data': data
            }
        )
    except Exception as e:
        logger.error(f"Failed to broadcast WebSocket update in task: {str(e)}")

@shared_task
def notify_parking_ended_task(session_id):
    """
    Async task to handle parking ended notifications and location checks.
    """
    from .notification_triggers import notify_parking_ended_sync
    from apps.parking.models import ParkingSession
    
    def _do_notify():
        try:
            session = ParkingSession.objects.get(id=session_id)
            notify_parking_ended_sync(session)
        except ParkingSession.DoesNotExist:
            logger.error(f"Session {session_id} not found for notify_parking_ended_task")
            
    try:
        _run_async_safe(_do_notify)
    except Exception as e:
        logger.error(f"Error in notify_parking_ended_task: {e}")
