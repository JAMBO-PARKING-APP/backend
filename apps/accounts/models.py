from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from phonenumber_field.modelfields import PhoneNumberField
from apps.common.models import BaseModel
from apps.common.constants import UserRole
from django.utils.translation import gettext_lazy as _
from .managers import UserManager

class User(AbstractBaseUser, PermissionsMixin, BaseModel):
    phone = PhoneNumberField(unique=True, verbose_name=_("Phone Number"))
    country = models.ForeignKey('common.Country', on_delete=models.SET_NULL, null=True, blank=True, related_name='users', verbose_name=_("Country"))
    email = models.EmailField(blank=True, null=True, verbose_name=_("Email Address"))
    first_name = models.CharField(max_length=30, verbose_name=_("First Name"))
    last_name = models.CharField(max_length=30, verbose_name=_("Last Name"))
    role = models.CharField(max_length=20, choices=UserRole.choices, default=UserRole.DRIVER, verbose_name=_("Role"))
    profile_photo = models.ImageField(upload_to='profiles/', null=True, blank=True, verbose_name=_("Profile Photo"))
    wallet_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name=_("Wallet Balance"))
    is_active = models.BooleanField(default=True, verbose_name=_("Active"))
    is_staff = models.BooleanField(default=False, verbose_name=_("Staff Status"))
    is_verified = models.BooleanField(default=False, verbose_name=_("Verified"))
    
    # Single device login enforcement
    current_device_id = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Current Device ID"), help_text="Unique identifier of the currently logged-in device")
    current_session_token = models.CharField(max_length=500, blank=True, null=  True, verbose_name=_("Current Session Token"), help_text="JWT token ID (jti) of active session")
    last_login_device = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Last Login Device"), help_text="Device info for logging purposes")
    
    # FCM Push Notification fields
    fcm_device_token = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("FCM Device Token"), help_text="Firebase Cloud Messaging device token for push notifications")
    fcm_token_updated_at = models.DateTimeField(null=True, blank=True, verbose_name=_("FCM Token Updated At"))
    
    # Chat availability for officers/support
    can_receive_chats = models.BooleanField(default=False, verbose_name=_("Can Receive Chats"), help_text="Whether this officer/agent is available to receive chat assignments")
    
    # Officer zone assignments
    assigned_zones = models.ManyToManyField(
        'parking.Zone',
        related_name='assigned_officers',
        blank=True,
        verbose_name=_("Assigned Zones"),
        help_text="Zones assigned to this officer for monitoring"
    )

    objects = UserManager()

    USERNAME_FIELD = 'phone'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    class Meta:
        indexes = [
            models.Index(fields=['is_active']),
            models.Index(fields=['phone']),
            models.Index(fields=['current_session_token']),
            models.Index(fields=['fcm_device_token']),
            models.Index(fields=['role'], name='acc_usr_role_idx'),
            models.Index(fields=['country'], name='acc_usr_cntry_idx'),
            models.Index(fields=['is_verified'], name='acc_usr_verif_idx'),
            models.Index(fields=['created_at'], name='acc_usr_created_idx'),
            models.Index(fields=['role', 'is_active'], name='acc_usr_role_act_idx'),
            models.Index(fields=['email'], name='acc_usr_email_idx'),
        ]

    def __str__(self):
        return str(self.phone)

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

    def save(self, *args, **kwargs):
        # Automatically assign country based on phone code if not set
        if not self.country and self.phone:
            try:
                import phonenumbers
                from phonenumbers import geocoder
                from apps.common.models import Country
                
                # Parse the phone number (PhoneNumber objects can be converted to string)
                parsed = phonenumbers.parse(str(self.phone), None)
                
                # Get ISO region code (e.g., 'UG', 'KE', 'US')
                region_code = phonenumbers.region_code_for_number(parsed)
                
                if region_code:
                    country = Country.objects.filter(iso_code=region_code, is_active=True).first()
                    if country:
                        self.country = country
                    else:
                        # Fallback to dialing code matching if ISO lookup fails (though unlikely)
                        dial_code = f"+{parsed.country_code}"
                        country = Country.objects.filter(phone_code=dial_code, is_active=True).first()
                        if country:
                            self.country = country

            except Exception:
                # Silently fail to ensure user can still sign up if parsing fails
                pass
                
        super().save(*args, **kwargs)

class Vehicle(BaseModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='vehicles')
    license_plate = models.CharField(max_length=20, unique=True)
    make = models.CharField(max_length=50)
    model = models.CharField(max_length=50)
    color = models.CharField(max_length=30)
    is_active = models.BooleanField(default=True, db_index=True)

    class Meta:
        indexes = [
            models.Index(fields=['user'], name='acc_veh_usr_idx'),
            models.Index(fields=['license_plate'], name='acc_veh_plate_idx'),
            models.Index(fields=['created_at'], name='acc_veh_created_idx'),
            models.Index(fields=['user', 'is_active'], name='acc_veh_usr_act_idx'),
        ]

    def __str__(self):
        return self.license_plate

class OTPCode(BaseModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    code = models.CharField(max_length=6)
    is_used = models.BooleanField(default=False)
    expires_at = models.DateTimeField()

    class Meta:
        indexes = [
            models.Index(fields=['user_id', 'is_used', 'expires_at']),
        ]

    def __str__(self):
        return f"{self.user.phone} - {self.code}"

class UserLocation(BaseModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='location_history')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    is_driver_app = models.BooleanField(default=True, help_text=_("True if sent from driver app, False if officer app"))

    class Meta:
        indexes = [
            models.Index(fields=['user', '-timestamp']),
            models.Index(fields=['latitude', 'longitude']),
            models.Index(fields=['timestamp']),
        ]
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.user.phone} at {self.timestamp}"