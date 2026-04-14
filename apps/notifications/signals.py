from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.signals import user_logged_in
from apps.accounts.models import User
from apps.notifications.services import NotificationService
import logging

logger = logging.getLogger(__name__)

@receiver(post_save, sender=User)
def user_country_updated(sender, instance, created, **kwargs):
    """Send welcome notification when user sets or updates their country"""
    if created:
        return
    
    try:
        old_instance = sender.objects.get(pk=instance.pk)
        if old_instance.country != instance.country and instance.country:
            NotificationService.send_country_welcome_notification(instance)
    except User.DoesNotExist:
        if instance.country:
            NotificationService.send_country_welcome_notification(instance)
    except Exception as e:
        logger.error(f"Error in user_country_updated signal: {e}")

@receiver(user_logged_in)
def user_login_handler(sender, request, user, **kwargs):
    """Check for country-specific notifications on login"""
    try:
        if user.country:
            pass
    except Exception as e:
        logger.error(f"Error in user_login_handler: {e}")
