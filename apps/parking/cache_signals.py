"""Invalidate zone list cache when zone metadata changes."""
from django.core.cache import cache
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

from .models import Zone


def invalidate_zone_list_cache():
    try:
        cache.delete_pattern('zone_list_country_*')
        cache.delete_pattern('zone_stats_*')
    except Exception:
        pass


@receiver(post_save, sender=Zone)
@receiver(post_delete, sender=Zone)
def _on_zone_changed_for_cache(sender, **kwargs):
    invalidate_zone_list_cache()
