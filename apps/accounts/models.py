from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models
from phonenumber_field.modelfields import PhoneNumberField
from apps.common.models import BaseModel
from apps.common.constants import UserRole
from django.utils.translation import gettext_lazy as _
from .managers import UserManager

class User(AbstractBaseUser, PermissionsMixin, BaseModel):
    phone = PhoneNumberField(unique=True, verbose_name=_("Phone Number"))
    email = models.EmailField(blank=True, null=True, verbose_name=_("Email Address"))
    first_name = models.CharField(max_length=30, verbose_name=_("First Name"))
    last_name = models.CharField(max_length=30, verbose_name=_("Last Name"))
    role = models.CharField(max_length=20, choices=UserRole.choices, default=UserRole.DRIVER, verbose_name=_("Role"))
    profile_photo = models.ImageField(upload_to='profiles/', null=True, blank=True, verbose_name=_("Profile Photo"))
    wallet_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name=_("Wallet Balance"))
    is_active = models.BooleanField(default=True, verbose_name=_("Active"))
    is_staff = models.BooleanField(default=False, verbose_name=_("Staff Status"))
    is_verified = models.BooleanField(default=False, verbose_name=_("Verified"))
    device_session_id = models.FloatField(default=0, verbose_name=_("Device Session ID"), help_text="Timestamp of last login - used for single device login")

    objects = UserManager()

    USERNAME_FIELD = 'phone'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    class Meta:
        indexes = [
            models.Index(fields=['is_active']),
            models.Index(fields=['phone']),
            models.Index(fields=['device_session_id']),
        ]

    def __str__(self):
        return str(self.phone)

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

class Vehicle(BaseModel):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='vehicles')
    license_plate = models.CharField(max_length=20, unique=True)
    make = models.CharField(max_length=50)
    model = models.CharField(max_length=50)
    color = models.CharField(max_length=30)
    is_active = models.BooleanField(default=True, db_index=True)

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