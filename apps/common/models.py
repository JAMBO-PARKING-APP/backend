import uuid
from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.common.constants import Currency, DEFAULT_CURRENCY

class BaseModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True

class Country(BaseModel):
    name = models.CharField(max_length=100, unique=True)
    iso_code = models.CharField(max_length=2, unique=True, help_text="ISO 3166-1 alpha-2 code (e.g. UG, KE)")
    currency = models.CharField(max_length=3, default=DEFAULT_CURRENCY)
    currency_symbol = models.CharField(max_length=10)
    timezone = models.CharField(max_length=50, default='Africa/Kampala')
    phone_code = models.CharField(max_length=10, help_text="Dialing code (e.g. +256)")
    flag_emoji = models.CharField(max_length=10, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = "Countries"
        ordering = ['name']

    def __str__(self):
        return self.name

import threading

_thread_locals = threading.local()

def get_current_country():
    return getattr(_thread_locals, 'country', None)

def set_current_country(country):
    _thread_locals.country = country

class RegionalManager(models.Manager):
    def get_queryset(self):
        qs = super().get_queryset()
        country = get_current_country()
        if country:
            return qs.filter(country=country)
        return qs

class RegionalModel(models.Model):
    """Mixin to add country field to regional models with automatic filtering"""
    country = models.ForeignKey(Country, on_delete=models.PROTECT, related_name="%(class)s_related", null=True, blank=True)
    
    objects = RegionalManager()
    all_objects = models.Manager() 

    class Meta:
        abstract = True

class SystemConfiguration(models.Model):
    """System-wide configuration settings"""
    currency = models.CharField(max_length=3, choices=Currency.choices, default=DEFAULT_CURRENCY)
    timezone = models.CharField(max_length=50, default='UTC')
    company_name = models.CharField(max_length=100, default='Smart Parking System')
    contact_email = models.EmailField(default='admin@smartparking.com')
    contact_phone = models.CharField(max_length=20, default='+1234567890')
    default_hourly_rate = models.DecimalField(max_digits=12, decimal_places=2, default=2000.00)
    violation_fine_amount = models.DecimalField(max_digits=12, decimal_places=2, default=50000.00)
    grace_period_minutes = models.IntegerField(default=15)
    
    # App Version Control
    min_android_version = models.CharField(max_length=20, default='1.0.0')
    min_ios_version = models.CharField(max_length=20, default='1.0.0')
    app_update_url = models.URLField(blank=True, null=True)
    force_update = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = 'System Configuration'
        verbose_name_plural = 'System Configuration'
    
    def save(self, *args, **kwargs):
        if not self.pk and SystemConfiguration.objects.exists():
            raise ValueError('Only one system configuration instance is allowed')
        super().save(*args, **kwargs)
    
    @classmethod
    def get_config(cls):
        """Get or create system configuration"""
        config, created = cls.objects.get_or_create(pk=1)
        return config


class CountryConfig(BaseModel):
    """Payment and currency configuration for each country"""
    country = models.OneToOneField(
        Country,
        on_delete=models.CASCADE,
        related_name='payment_config',
        help_text="Country this configuration applies to"
    )
    payment_methods = models.JSONField(
        default=list,
        help_text="Available payment methods: ['wallet', 'pesapal', 'mpesa', 'flutterwave']"
    )
    exchange_rate_to_base = models.DecimalField(
        max_digits=10,
        decimal_places=4,
        default=1.0,
        help_text="Exchange rate from base currency (UGX) to this country's currency"
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = _("Country Payment Configuration")
        verbose_name_plural = _("Country Payment Configurations")

    def __str__(self):
        return f"{self.country.name} Payment Config"