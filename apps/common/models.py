import uuid
from django.db import models
from apps.common.constants import Currency, DEFAULT_CURRENCY

class BaseModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True

class SystemConfiguration(models.Model):
    """System-wide configuration settings"""
    currency = models.CharField(max_length=3, choices=Currency.choices, default=DEFAULT_CURRENCY)
    timezone = models.CharField(max_length=50, default='UTC')
    company_name = models.CharField(max_length=100, default='Smart Parking System')
    contact_email = models.EmailField(default='admin@smartparking.com')
    contact_phone = models.CharField(max_length=20, default='+1234567890')
    
    class Meta:
        verbose_name = 'System Configuration'
        verbose_name_plural = 'System Configuration'
    
    def save(self, *args, **kwargs):
        # Ensure only one configuration instance exists
        if not self.pk and SystemConfiguration.objects.exists():
            raise ValueError('Only one system configuration instance is allowed')
        super().save(*args, **kwargs)
    
    @classmethod
    def get_config(cls):
        """Get or create system configuration"""
        config, created = cls.objects.get_or_create(pk=1)
        return config