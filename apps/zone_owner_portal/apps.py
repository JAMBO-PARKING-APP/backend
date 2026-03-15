from django.apps import AppConfig


class ZoneOwnerPortalConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.zone_owner_portal'
    verbose_name = 'Zone Owner Portal'

    def ready(self):
        print("DEBUG: ZoneOwnerPortalConfig.ready() called")
        import apps.zone_owner_portal.signals  # noqa
