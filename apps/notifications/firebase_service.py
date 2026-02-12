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

# Initialize Firebase Admin SDK
_firebase_initialized = False

def initialize_firebase():
    """Initialize Firebase Admin SDK with service account credentials"""
    global _firebase_initialized
    
    if _firebase_initialized:
        return
    
    if not settings.FIREBASE_ENABLED:
        logger.info("Firebase is disabled in settings")
        return
    
    try:
        cred = credentials.Certificate(str(settings.FIREBASE_CREDENTIALS_PATH))
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase Admin SDK initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        raise


def send_notification_to_user(
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
        # Ensure Firebase is initialized
        if not _firebase_initialized:
            initialize_firebase()
        
        # Prepare notification data
        notification_data = data or {}
        notification_data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK'
        
        # Create FCM message
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
                    channel_id='default',
                    icon='launcher_icon',
                    color='#4CAF50',
                ),
            ),
        )
        
        # Send message
        response = messaging.send(message)
        logger.info(f"Successfully sent notification to user {user.id}: {response}")
        
        # Update notification event if provided
        if notification_event:
            notification_event.sent_via_push = True
            notification_event.push_sent_at = timezone.now()
            notification_event.save(update_fields=['sent_via_push', 'push_sent_at'])
        
        return True
        
    except messaging.UnregisteredError:
        logger.warning(f"FCM token for user {user.id} is invalid or unregistered, clearing token")
        # Clear invalid token
        user.fcm_device_token = None
        user.fcm_token_updated_at = None
        user.save(update_fields=['fcm_device_token', 'fcm_token_updated_at'])
        
        if notification_event:
            notification_event.push_error = "Device token unregistered"
            notification_event.save(update_fields=['push_error'])
        
        return False
        
    except Exception as e:
        logger.error(f"Failed to send notification to user {user.id}: {e}")
        
        if notification_event:
            notification_event.push_error = str(e)
            notification_event.save(update_fields=['push_error'])
        
        return False


def send_notification_to_multiple_users(
    users,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None
) -> Dict[str, int]:
    """
    Send a push notification to multiple users
    
    Args:
        users: QuerySet or list of User instances
        title: Notification title
        body: Notification body text
        data: Optional dictionary of custom data
    
    Returns:
        dict: Statistics with 'success', 'failed', and 'no_token' counts
    """
    stats = {'success': 0, 'failed': 0, 'no_token': 0}
    
    for user in users:
        if not user.fcm_device_token:
            stats['no_token'] += 1
            continue
        
        success = send_notification_to_user(user, title, body, data)
        if success:
            stats['success'] += 1
        else:
            stats['failed'] += 1
    
    logger.info(f"Batch notification sent: {stats}")
    return stats


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
                    channel_id='default',
                    icon='launcher_icon',
                    color='#4CAF50',
                ),
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
