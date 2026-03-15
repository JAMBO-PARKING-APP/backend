import uuid
from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.common.models import BaseModel


class ApplicationStatus(models.TextChoices):
    PENDING = 'pending', _('Pending')
    APPROVED = 'approved', _('Approved')
    REJECTED = 'rejected', _('Rejected')


class ZoneApplicationPublic(BaseModel):
    """
    Public zone application – submitted without needing an account.
    Captures applicant contact details and zone proposal.
    """
    application_id = models.UUIDField(default=uuid.uuid4, unique=True, editable=False,
                                      help_text="Public-facing unique identifier for the application")

    # Applicant details
    applicant_name = models.CharField(max_length=100)
    applicant_email = models.EmailField()
    applicant_phone = models.CharField(max_length=30)

    # Zone proposal
    proposed_name = models.CharField(max_length=100)
    address = models.TextField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    total_slots = models.IntegerField(default=1)
    proposed_hourly_rate = models.DecimalField(max_digits=12, decimal_places=2)
    operating_hours = models.CharField(max_length=100, default="24/7",
                                       help_text="E.g. 24/7, 8 AM - 6 PM")
    parking_surface = models.CharField(max_length=50, choices=[
        ('paved', _('Paved/Concrete')),
        ('gravel', _('Gravel/Dirt')),
        ('indoor', _('Indoor/Garage')),
    ], default='paved')
    has_security = models.BooleanField(default=False)
    has_cctv = models.BooleanField(default=False)
    access_instructions = models.TextField(blank=True)
    documents = models.FileField(upload_to='zone_applications/public/', null=True, blank=True,
                                 help_text="Proof of ownership or ID")

    # Admin processing
    status = models.CharField(max_length=20, choices=ApplicationStatus.choices,
                              default=ApplicationStatus.PENDING, db_index=True)
    admin_notes = models.TextField(blank=True)

    # Demo credentials — generated when application is approved
    demo_email = models.EmailField(blank=True, help_text="Login email sent to the applicant upon approval")
    demo_password = models.CharField(max_length=100, blank=True,
                                     help_text="Temporary password generated upon approval — shown once, remind owner to change it")

    # Link to created zone after approval
    created_zone = models.ForeignKey(
        'parking.Zone', on_delete=models.SET_NULL,
        null=True, blank=True, related_name='public_application'
    )

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Zone Application'
        verbose_name_plural = 'Zone Applications'

    def __str__(self):
        return f"{self.proposed_name} – {self.applicant_name} ({self.get_status_display()})"


class OwnerBankDetails(BaseModel):
    """
    Bank account details for a zone owner – where earnings are deposited.
    Required to be filled on first login to the partner portal.
    """
    user = models.OneToOneField(
        'accounts.User', on_delete=models.CASCADE,
        related_name='bank_details'
    )
    bank_name = models.CharField(max_length=100)
    account_number = models.CharField(max_length=50)
    account_holder_name = models.CharField(max_length=100)

    class Meta:
        verbose_name = 'Owner Bank Details'
        verbose_name_plural = 'Owner Bank Details'

    def __str__(self):
        return f"{self.user.email or self.user.phone} – {self.bank_name}"


from apps.accounts.models import User
from apps.common.constants import UserRole

class ZoneOwner(User):
    """
    Proxy model to allow a specialized Django Admin view strictly for 
    users with the ZONE_OWNER role, without recreating the table.
    """
    class Meta:
        proxy = True
        verbose_name = 'Zone Owner (Partner)'
        verbose_name_plural = 'Zone Owners (Partners)'
