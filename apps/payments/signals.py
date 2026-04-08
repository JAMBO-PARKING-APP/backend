"""
Invalidate Pesapal auth/IPN cache when credentials change in admin so new keys apply immediately.
"""
from typing import Optional
from django.core.cache import cache
from django.db.models.signals import pre_save, post_save, post_delete
from django.dispatch import receiver
from apps.common.models import Country
from .models import PaymentGatewayConfig, PaymentGateway


def _invalidate_user_payment_country_cache():
    try:
        cache.delete_pattern('user_payment_country_config:*')
    except Exception:
        pass


def _pesapal_cache_keys_for_consumer_key(consumer_key: str):
    if not consumer_key or len(consumer_key) < 8:
        return []
    prefix = consumer_key[:8]
    keys = []
    for env in ('sandbox', 'live'):
        keys.append(f'pesapal_auth_token_{env}_{prefix}')
        keys.append(f'pesapal_ipn_id_{env}_{prefix}')
    return keys


def invalidate_pesapal_cache_for_credentials(consumer_key: Optional[str]):
    for k in _pesapal_cache_keys_for_consumer_key(consumer_key or ''):
        cache.delete(k)


@receiver(pre_save, sender=PaymentGatewayConfig)
def _pgw_store_old_consumer_key(sender, instance, **kwargs):
    instance._pesapal_old_key = None
    if not instance.pk:
        return
    try:
        prev = PaymentGatewayConfig.all_objects.get(pk=instance.pk)
        instance._pesapal_old_key = (prev.credentials or {}).get('consumer_key')
    except PaymentGatewayConfig.DoesNotExist:
        pass


@receiver(post_save, sender=PaymentGatewayConfig)
def _pgw_clear_pesapal_cache_save(sender, instance, **kwargs):
    if instance.gateway != PaymentGateway.PESAPAL:
        return
    old_key = getattr(instance, '_pesapal_old_key', None)
    new_key = (instance.credentials or {}).get('consumer_key')
    for key in {old_key, new_key}:
        if key:
            invalidate_pesapal_cache_for_credentials(key)


@receiver(post_delete, sender=PaymentGatewayConfig)
def _pgw_clear_pesapal_cache_delete(sender, instance, **kwargs):
    if instance.gateway != PaymentGateway.PESAPAL:
        return
    key = (instance.credentials or {}).get('consumer_key')
    invalidate_pesapal_cache_for_credentials(key)


@receiver(post_save, sender=PaymentGatewayConfig)
@receiver(post_delete, sender=PaymentGatewayConfig)
def _pgw_invalidate_country_api_cache(sender, **kwargs):
    _invalidate_user_payment_country_cache()


@receiver(post_save, sender=Country)
@receiver(post_delete, sender=Country)
def _country_config_invalidate_payment_api_cache(sender, **kwargs):
    _invalidate_user_payment_country_cache()
