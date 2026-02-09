from django.db import models
from django.contrib.postgres.fields import JSONField
from apps.common.models import BaseModel

class NotificationEvent(BaseModel):
    NOTIFICATION_TYPES = [
        ('parking_ended', 'Parking Ended'),
        ('violation_received', 'Violation Received'),
        ('payment_successful', 'Payment Successful'),
        ('payment_failed', 'Payment Failed'),
        ('reservation_confirmed', 'Reservation Confirmed'),
        ('reservation_cancelled', 'Reservation Cancelled'),
        ('maintenance_alert', 'Maintenance Alert'),
        ('system_alert', 'System Alert'),
        ('promotional_offer', 'Promotional Offer'),
        ('other', 'Other'),
    ]
    
    CATEGORIES = [
        ('parking', 'Parking'),
        ('violations', 'Violations'),
        ('payments', 'Payments'),
        ('reservations', 'Reservations'),
        ('system', 'System'),
        ('promo', 'Promotions'),
    ]
    
    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=100)
    message = models.TextField()
    type = models.CharField(max_length=50, choices=NOTIFICATION_TYPES, default='other')
    category = models.CharField(max_length=20, choices=CATEGORIES, default='system')
    is_read = models.BooleanField(default=False)
    metadata = models.JSONField(null=True, blank=True)  # Store additional data like parking_session_id, violation_id
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Notification Event'
        verbose_name_plural = 'Notification Events'
    
    def __str__(self):
        return f"{self.user.phone} - {self.title}"


class UserPreferences(BaseModel):
    """Store user preferences like language, currency, notification settings"""
    LANGUAGE_CHOICES = [
        ('en', 'English'),
        ('fr', 'Français'),
        ('es', 'Español'),
        ('pt', 'Português'),
        ('sw', 'Swahili'),
        ('am', 'አማርኛ'),
        ('ar', 'العربية'),
        ('de', 'Deutsch'),
    ]
    
    CURRENCY_CHOICES = [
        ('USD', 'US Dollar'),
        ('EUR', 'Euro'),
        ('GBP', 'British Pound'),
        ('ZAR', 'South African Rand'),
        ('NGN', 'Nigerian Naira'),
        ('KES', 'Kenyan Shilling'),
        ('GHS', 'Ghanaian Cedi'),
        ('EGP', 'Egyptian Pound'),
        ('UGX', 'Uganda Shilling'),
    ]
    
    user = models.OneToOneField('accounts.User', on_delete=models.CASCADE, related_name='preferences')
    language = models.CharField(max_length=5, choices=LANGUAGE_CHOICES, default='en')
    currency = models.CharField(max_length=3, choices=CURRENCY_CHOICES, default='USD')
    
    # Notification Preferences
    enable_parking_notifications = models.BooleanField(default=True)
    enable_violation_notifications = models.BooleanField(default=True)
    enable_payment_notifications = models.BooleanField(default=True)
    enable_promotional_notifications = models.BooleanField(default=True)
    enable_push_notifications = models.BooleanField(default=True)
    enable_sms_notifications = models.BooleanField(default=False)
    enable_email_notifications = models.BooleanField(default=True)
    
    # Display Preferences
    theme_mode = models.CharField(
        max_length=10,
        choices=[('light', 'Light'), ('dark', 'Dark'), ('auto', 'Auto')],
        default='auto'
    )
    font_size = models.CharField(
        max_length=10,
        choices=[('small', 'Small'), ('normal', 'Normal'), ('large', 'Large')],
        default='normal'
    )
    
    # Privacy Settings
    biometric_enabled = models.BooleanField(default=False)
    two_factor_enabled = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = 'User Preference'
        verbose_name_plural = 'User Preferences'
    
    def __str__(self):
        return f"Preferences for {self.user.phone}"
    # Optional references
    parking_session = models.ForeignKey('parking.ParkingSession', on_delete=models.CASCADE, null=True, blank=True)
    transaction = models.ForeignKey('payments.Transaction', on_delete=models.CASCADE, null=True, blank=True)

    def __str__(self):
        return f"{self.user.phone} - {self.title}"