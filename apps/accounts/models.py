from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models, transaction
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
    wallet_balance_legacy = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name=_("Legacy Wallet Balance"), db_column='wallet_balance')
    is_active = models.BooleanField(default=True, verbose_name=_("Active"))
    is_staff = models.BooleanField(default=False, verbose_name=_("Staff Status"))
    is_verified = models.BooleanField(default=False, verbose_name=_("Verified"))
    current_device_id = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Current Device ID"), help_text="Unique identifier of the currently logged-in device")
    current_session_token = models.CharField(max_length=500, blank=True, null=  True, verbose_name=_("Current Session Token"), help_text="JWT token ID (jti) of active session")
    last_login_device = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Last Login Device"), help_text="Device info for logging purposes")
    fcm_device_token = models.TextField(blank=True, null=True, verbose_name=_("FCM Device Token"), help_text="Firebase Cloud Messaging device token for push notifications")
    fcm_token_updated_at = models.DateTimeField(null=True, blank=True, verbose_name=_("FCM Token Updated At"))
    can_receive_chats = models.BooleanField(default=False, verbose_name=_("Can Receive Chats"), help_text="Whether this officer/agent is available to receive chat assignments")
    deletion_requested_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Deletion Requested At"))
    deletion_planned_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Deletion Planned At"), help_text="Scheduled date for permanent deletion")
    app_version = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("App Version"))
    device_model = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Device Model"))
    device_os = models.CharField(max_length=20, choices=[('android', 'Android'), ('ios', 'iOS')], blank=True, null=True, verbose_name=_("Device OS"))

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
            models.Index(fields=['deletion_planned_at'], name='acc_usr_del_plan_idx'),
        ]

    def __str__(self):
        return str(self.phone)

    @property
    def wallet_balance(self):
        """Returns the wallet balance for the current active country context."""
        from apps.common.models import get_current_country
        active_country = get_current_country() or self.country
        
        if not active_country:
            return self.wallet_balance_legacy
            
        wallet, _ = Wallet.objects.get_or_create(user=self, country=active_country)
        return wallet.balance

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

    def get_full_name(self):
        return self.full_name

    @transaction.atomic
    def adjust_wallet_balance(self, amount, country=None, transaction_type=None, description=None, parking_session=None):
        """
        Adjusts the user's wallet balance.
        Positive amount for deposits/refunds, negative for payments.
        """
        from apps.payments.models import WalletTransaction
        from django.db.models import F
        target_country = country or self.country
        
        if target_country:
            wallet, _ = Wallet.objects.select_for_update().get_or_create(user=self, country=target_country)
            opening_balance = wallet.balance
            wallet.balance = F('balance') + amount
            wallet.save(update_fields=['balance'])
            wallet.refresh_from_db()
            closing_balance = wallet.balance
        else:
            opening_balance = self.wallet_balance_legacy
            self.wallet_balance_legacy = F('wallet_balance_legacy') + amount
            self.save(update_fields=['wallet_balance_legacy'])
            self.refresh_from_db()
            closing_balance = self.wallet_balance_legacy

        if transaction_type:
            return WalletTransaction.objects.create(
                user=self,
                amount=amount,
                transaction_type=transaction_type,
                description=description or f"Wallet adjustment: {amount}",
                parking_session=parking_session,
                country=target_country,
                opening_balance=opening_balance,
                closing_balance=closing_balance,
                status='completed'
            )

    def save(self, *args, **kwargs):
        if not self.country and self.phone:
            try:
                import phonenumbers
                from phonenumbers import geocoder
                from apps.common.models import Country
                parsed = phonenumbers.parse(str(self.phone), None)
                region_code = phonenumbers.region_code_for_number(parsed)
                
                if region_code:
                    country = Country.objects.filter(iso_code=region_code, is_active=True).first()
                    if country:
                        self.country = country
                    else:
                        dial_code = f"+{parsed.country_code}"
                        country = Country.objects.filter(phone_code=dial_code, is_active=True).first()
                        if country:
                            self.country = country

            except Exception:
                pass
                
        if self.is_active:
            self.deletion_requested_at = None
            self.deletion_planned_at = None

        super().save(*args, **kwargs)

class Wallet(RegionalModel, BaseModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='wallets')
    balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name=_("Balance"))

    class Meta:
        unique_together = ('user', 'country')
        verbose_name = _("Wallet")
        verbose_name_plural = _("Wallets")

    def __str__(self):
        return f"{self.user.phone} - {self.country.iso_code}: {self.balance}"

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