from celery import shared_task
from django.contrib.auth import get_user_model
from . import firebase_service, twilio_service
import logging

logger = logging.getLogger(__name__)
User = get_user_model()

@shared_task
def send_firebase_notification_task(user_id, title, body, data=None, notification_event_id=None):
    """
    Async task to send Firebase notification to a user.
    """
    try:
        user = User.objects.get(id=user_id)
        
        notification_event = None
        if notification_event_id:
            from .models import NotificationEvent
            try:
                notification_event = NotificationEvent.objects.get(id=notification_event_id)
            except NotificationEvent.DoesNotExist:
                logger.warning(f"NotificationEvent {notification_event_id} not found in task")
        
        # Call the synchronous implementation
        firebase_service.send_notification_to_user_sync(user, title, body, data, notification_event)
        
    except User.DoesNotExist:
        logger.error(f"User {user_id} not found for notification task")
    except Exception as e:
        logger.error(f"Error in send_firebase_notification_task: {e}")

@shared_task
def send_twilio_verification_task(to_phone, channel='sms'):
    """
    Async task to send Twilio verification.
    """
    try:
        # Call the synchronous implementation
        twilio_service.send_verification_sync(to_phone, channel)
    except Exception as e:
        logger.error(f"Error in send_twilio_verification_task: {e}")

