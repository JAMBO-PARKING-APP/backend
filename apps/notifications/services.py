from django.utils import timezone
from apps.notifications.models import NotificationEvent
from apps.accounts.models import User
import logging

logger = logging.getLogger(__name__)

class NotificationService:
    
    @staticmethod
    def send_country_welcome_notification(user):
        """Send welcome notification when user enters a new country"""
        if not user.country:
            return
            
        try:
            NotificationEvent.objects.create(
                user=user,
                title=f'Welcome to {user.country.name}!',
                message=f'SPACE is now available in {user.country.name}. Enjoy parking with local currency {user.country.currency_symbol} and country-specific features.',
                type='country_welcome',
                category='system',
                priority='medium',
                show_as_dialog=True,
                metadata={
                    'country_code': user.country.iso_code,
                    'country_name': user.country.name,
                    'currency': user.country.currency,
                    'currency_symbol': user.country.currency_symbol,
                }
            )
            logger.info(f"Country welcome notification sent to user {user.phone} for {user.country.name}")
        except Exception as e:
            logger.error(f"Failed to send country welcome notification: {e}")
    
    @staticmethod
    def send_country_alert_notification(user, title, message, alert_type='info'):
        """Send country-specific alert notification"""
        if not user.country:
            return
            
        try:
            NotificationEvent.objects.create(
                user=user,
                title=title,
                message=message,
                type='country_alert',
                category='system',
                priority='high' if alert_type == 'urgent' else 'medium',
                show_as_dialog=True,
                metadata={
                    'country_code': user.country.iso_code,
                    'country_name': user.country.name,
                    'alert_type': alert_type,
                }
            )
            logger.info(f"Country alert notification sent to user {user.phone}")
        except Exception as e:
            logger.error(f"Failed to send country alert notification: {e}")
    
    @staticmethod
    def send_reservation_confirmed_notification(user, reservation_data):
        """Send notification when reservation is confirmed"""
        try:
            NotificationEvent.objects.create(
                user=user,
                title='Reservation Confirmed!',
                message=f'Your parking reservation at {reservation_data.get("zone_name", "selected zone")} has been confirmed. Start time: {reservation_data.get("start_time", "N/A")}',
                type='reservation_confirmed',
                category='reservations',
                priority='medium',
                metadata={
                    'reservation_id': reservation_data.get('id'),
                    'zone_id': reservation_data.get('zone_id'),
                    'zone_name': reservation_data.get('zone_name'),
                    'start_time': reservation_data.get('start_time'),
                    'end_time': reservation_data.get('end_time'),
                    'vehicle_plate': reservation_data.get('vehicle_plate'),
                }
            )
            logger.info(f"Reservation confirmed notification sent to user {user.phone}")
        except Exception as e:
            logger.error(f"Failed to send reservation confirmed notification: {e}")
    
    @staticmethod
    def send_reservation_reminder_notification(user, reservation_data):
        """Send reminder notification before reservation starts"""
        try:
            NotificationEvent.objects.create(
                user=user,
                title='Reservation Starting Soon',
                message=f'Your parking reservation at {reservation_data.get("zone_name", "selected zone")} starts in 30 minutes. Be ready to start your session!',
                type='reservation_reminder',
                category='reservations',
                priority='medium',
                metadata={
                    'reservation_id': reservation_data.get('id'),
                    'zone_id': reservation_data.get('zone_id'),
                    'zone_name': reservation_data.get('zone_name'),
                    'start_time': reservation_data.get('start_time'),
                    'vehicle_plate': reservation_data.get('vehicle_plate'),
                }
            )
            logger.info(f"Reservation reminder notification sent to user {user.phone}")
        except Exception as e:
            logger.error(f"Failed to send reservation reminder notification: {e}")
    
    @staticmethod
    def send_reservation_cancelled_notification(user, reservation_data):
        """Send notification when reservation is cancelled"""
        try:
            NotificationEvent.objects.create(
                user=user,
                title='Reservation Cancelled',
                message=f'Your parking reservation at {reservation_data.get("zone_name", "selected zone")} has been cancelled.',
                type='reservation_cancelled',
                category='reservations',
                priority='medium',
                metadata={
                    'reservation_id': reservation_data.get('id'),
                    'zone_id': reservation_data.get('zone_id'),
                    'zone_name': reservation_data.get('zone_name'),
                    'cancelled_at': timezone.now().isoformat(),
                }
            )
            logger.info(f"Reservation cancelled notification sent to user {user.phone}")
        except Exception as e:
            logger.error(f"Failed to send reservation cancelled notification: {e}")
    
    @staticmethod
    def create_notification_for_users_in_country(country, title, message, notification_type='country_alert', priority='medium'):
        """Send notification to all users in a specific country"""
        try:
            users_in_country = User.objects.filter(country=country, is_active=True)
            notifications_created = 0
            
            for user in users_in_country:
                NotificationEvent.objects.create(
                    user=user,
                    title=title,
                    message=message,
                    type=notification_type,
                    category='system',
                    priority=priority,
                    metadata={
                        'country_code': country.iso_code,
                        'country_name': country.name,
                        'bulk_notification': True,
                    }
                )
                notifications_created += 1
            
            logger.info(f"Bulk country notification sent to {notifications_created} users in {country.name}")
            return notifications_created
        except Exception as e:
            logger.error(f"Failed to send bulk country notification: {e}")
            return 0
