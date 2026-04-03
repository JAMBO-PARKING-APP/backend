"""
Firebase Cloud Messaging Service for Push Notifications

This module handles all Firebase Admin SDK operations for sending push notifications
to user devices via Firebase Cloud Messaging (FCM).
"""

import logging
from typing import Optional, Dict, List, Any
from django.conf import settings
from django.utils import timezone
import firebase_admin
from firebase_admin import credentials, messaging

logger = logging.getLogger(__name__)

_firebase_initialized = False

def initialize_firebase():
    """Initialize Firebase Admin SDK with service account credentials"""
    if not settings.FIREBASE_ENABLED:
        logger.info("Firebase is disabled in settings")
        return
    
    try:
        # Check if app is already initialized to avoid ValueError
        try:
            firebase_admin.get_app()
            logger.debug("Firebase Admin SDK already initialized")
            return
        except ValueError:
            # App not yet initialized, proceed
            pass

        cred_path = str(settings.FIREBASE_CREDENTIALS_PATH)
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        # Don't re-raise in production to prevent crashing the whole process
        if settings.DEBUG:
            raise


def send_notification_to_user_sync(
    user,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
    notification_event=None
) -> bool:
    """
    Send a push notification to a specific user
    
    Args:
        user: User instance
        title: Notification title
        body: Notification body text
        data: Optional dictionary of custom data to send with notification
        notification_event: Optional NotificationEvent instance to update with push status
    
    Returns:
        bool: True if notification was sent successfully, False otherwise
    """
    if not settings.FIREBASE_ENABLED:
        logger.debug("Firebase is disabled, skipping push notification")
        return False
    
    if not user.fcm_device_token:
        logger.debug(f"User {user.id} has no FCM device token")
        return False
    
    try:
        if not _firebase_initialized:
            initialize_firebase()
        notification_data = data or {}
        notification_data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK'
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=notification_data,
            token=user.fcm_device_token,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    icon='launcher_icon',
                    color='#4CAF50',
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=1,
                        content_available=True,
                    ),
                ),
                headers={
                    'apns-priority': '10',
                },
            ),
        )
        
        response = messaging.send(message)
        logger.info(f"Successfully sent notification to user {user.id}: {response}")
        if notification_event:
            notification_event.sent_via_push = True
            notification_event.push_sent_at = timezone.now()
            _safe_save(notification_event, update_fields=['sent_via_push', 'push_sent_at'])
        
        return True
        
    except messaging.UnregisteredError:
        logger.warning(f"FCM token for user {user.id} is invalid or unregistered, clearing token")
        user.fcm_device_token = None
        user.fcm_token_updated_at = None
        _safe_save(user, update_fields=['fcm_device_token', 'fcm_token_updated_at'])
        
        if notification_event:
            notification_event.push_error = "Device token unregistered"
            _safe_save(notification_event, update_fields=['push_error'])
        
        return False
        
    except Exception as e:
        logger.error(f"Failed to send notification to user {user.id}: {e}")
        
        if notification_event:
            notification_event.push_error = str(e)
            _safe_save(notification_event, update_fields=['push_error'])
        
        return False


def send_notification_to_user(
    user,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None,
    notification_event=None
) -> bool:
    """
    Async wrapper for sending push notification to a user.
    """
    notification_event_id = str(notification_event.id) if notification_event else None
    
    from . import tasks
    from django.db import transaction
    transaction.on_commit(lambda: tasks.send_firebase_notification_task.delay(
        user.id,
        title,
        body,
        data,
        notification_event_id
    ))

    return True


def send_multicast_sync(
    users,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None
) -> Dict[str, int]:
    """
    Send push notifications to multiple users in efficient batches.
    Uses messaging.send_each for optimal performance.
    """
    if not settings.FIREBASE_ENABLED:
        return {'success': 0, 'failed': 0, 'no_token': 0}
        
    tokens = [u.fcm_device_token for u in users if u.fcm_device_token]
    if not tokens:
        return {'success': 0, 'failed': 0, 'no_token': 0}
        
    try:
        if not _firebase_initialized:
            initialize_firebase()
            
        notification_data = data or {}
        notification_data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK'
        
        messages = [
            messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=notification_data,
                token=token,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        sound='default',
                        icon='launcher_icon',
                        color='#4CAF50',
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                            content_available=True,
                        ),
                    ),
                    headers={
                        'apns-priority': '10',
                    },
                ),
            ) for token in tokens
        ]
        
        batch_response = messaging.send_each(messages)
        success_count = batch_response.success_count
        failure_count = batch_response.failure_count
        
        logger.info(f"Multicast sent: {success_count} success, {failure_count} failure")
        return {
            'success': success_count,
            'failed': failure_count,
            'no_token': len(users) - len(tokens)
        }
    except Exception as e:
        logger.error(f"Multicast failed: {e}")
        return {'success': 0, 'failed': len(tokens), 'no_token': len(users) - len(tokens)}


def send_notification_to_multiple_users(
    users,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None
) -> bool:
    """
    Asynchronously send notifications to multiple users using a single Celery task.
    """
    user_ids = [str(u.id) for u in users]
    if not user_ids:
        return False
        
    from . import tasks
    from django.db import transaction
    transaction.on_commit(lambda: tasks.send_multicast_notification_task.delay(
        user_ids,
        title,
        body,
        data
    ))

    return True


def send_notification_to_topic(
    topic: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None
) -> bool:
    """
    Send a push notification to a topic (group of users)
    
    Args:
        topic: Topic name (e.g., 'all_users', 'drivers', 'officers')
        title: Notification title
        body: Notification body text
        data: Optional dictionary of custom data
    
    Returns:
        bool: True if notification was sent successfully
    """
    if not settings.FIREBASE_ENABLED:
        return False
    
    try:
        if not _firebase_initialized:
            initialize_firebase()
        
        notification_data = data or {}
        notification_data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK'
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=notification_data,
            topic=topic,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    icon='launcher_icon',
                    color='#4CAF50',
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=1,
                        content_available=True,
                    ),
                ),
                headers={
                    'apns-priority': '10',
                },
            ),
        )
        
        response = messaging.send(message)
        logger.info(f"Successfully sent notification to topic '{topic}': {response}")
        return True
        
    except Exception as e:
        logger.error(f"Failed to send notification to topic '{topic}': {e}")
        return False


def subscribe_to_topic(token: str, topic: str) -> bool:
    """
    Subscribe a device token to a topic
    
    Args:
        token: FCM device token
        topic: Topic name
    
    Returns:
        bool: True if subscription was successful
    """
    try:
        if not _firebase_initialized:
            initialize_firebase()
        
        response = messaging.subscribe_to_topic([token], topic)
        logger.info(f"Subscribed token to topic '{topic}': {response.success_count} success, {response.failure_count} failures")
        return response.success_count > 0
        
    except Exception as e:
        logger.error(f"Failed to subscribe to topic '{topic}': {e}")
        return False


def unsubscribe_from_topic(token: str, topic: str) -> bool:
    """
    Unsubscribe a device token from a topic
    
    Args:
        token: FCM device token
        topic: Topic name
    
    Returns:
        bool: True if unsubscription was successful
    """
    try:
        if not _firebase_initialized:
            initialize_firebase()
        
        response = messaging.unsubscribe_from_topic([token], topic)
        logger.info(f"Unsubscribed token from topic '{topic}': {response.success_count} success, {response.failure_count} failures")
        return response.success_count > 0
        
    except Exception as e:
        logger.error(f"Failed to unsubscribe from topic '{topic}': {e}")
        return False

def _safe_save(instance, **kwargs):
    """Helper to save model instances in a way that handles async contexts"""
    import os
    from asgiref.sync import async_to_sync
    
    os.environ["DJANGO_ALLOW_ASYNC_UNSAFE"] = "true"
    try:
        instance.save(**kwargs)
    finally:
        pass
