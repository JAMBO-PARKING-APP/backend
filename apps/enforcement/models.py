from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.common.models import BaseModel, RegionalModel
from apps.common.constants import ViolationType

class Violation(RegionalModel, BaseModel):
    vehicle = models.ForeignKey('accounts.Vehicle', on_delete=models.CASCADE, related_name='violations', verbose_name=_("Vehicle"))
    officer = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='issued_violations', verbose_name=_("Officer"))
    zone = models.ForeignKey('parking.Zone', on_delete=models.CASCADE, related_name='violations', verbose_name=_("Zone"))
    parking_session = models.ForeignKey('parking.ParkingSession', on_delete=models.SET_NULL, 
                                       null=True, blank=True, related_name='violations', verbose_name=_("Parking Session"))
    
    violation_type = models.CharField(max_length=20, choices=ViolationType.choices, verbose_name=_("Violation Type"), db_index=True)
    description = models.TextField(verbose_name=_("Description"))
    fine_amount = models.DecimalField(max_digits=8, decimal_places=2, verbose_name=_("Fine Amount"))
    latitude = models.DecimalField(max_digits=9, decimal_places=6, verbose_name=_("Latitude"))
    longitude = models.DecimalField(max_digits=9, decimal_places=6, verbose_name=_("Longitude"))
    
    is_paid = models.BooleanField(default=False, verbose_name=_("Is Paid"), db_index=True)
    paid_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Paid At"))

    class Meta:
        indexes = [
            models.Index(fields=['vehicle'], name='enf_violation_vehicle_idx'),
            models.Index(fields=['officer'], name='enf_violation_officer_idx'),
            models.Index(fields=['zone'], name='enf_violation_zone_idx'),
            models.Index(fields=['created_at'], name='enf_violation_created_at_idx'),
            models.Index(fields=['officer', 'created_at'], name='enf_viol_off_cr_idx'),
            models.Index(fields=['is_paid', 'created_at'], name='enf_viol_paid_cr_idx'),
            models.Index(fields=['violation_type'], name='enf_violation_type_idx'),
        ]

    def __str__(self):
        return f"{self.vehicle.license_plate} - {self.violation_type} (${self.fine_amount})"

    def save(self, *args, **kwargs):
        if self.zone and not self.country:
            self.country = self.zone.country
        super().save(*args, **kwargs)

class ViolationEvidence(BaseModel):
    violation = models.ForeignKey(Violation, on_delete=models.CASCADE, related_name='evidence')
    image = models.ImageField(upload_to='violations/')
    description = models.CharField(max_length=200, blank=True)

    def __str__(self):
        return f"Evidence for {self.violation}"

class OfficerLog(BaseModel):
    officer = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='activity_logs')
    action = models.CharField(max_length=50)  
    details = models.JSONField(default=dict)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['officer', '-created_at']),
            models.Index(fields=['action', '-created_at']),
            models.Index(fields=['created_at'], name='enf_log_cr_idx'),
        ]

    def __str__(self):
        return f"{self.officer.full_name} - {self.action}"

class OfficerStatus(BaseModel):
    """Track current online/offline status of officers"""
    officer = models.OneToOneField('accounts.User', on_delete=models.CASCADE, related_name='officer_status')
    is_online = models.BooleanField(default=False)
    went_online_at = models.DateTimeField(null=True, blank=True)
    went_offline_at = models.DateTimeField(null=True, blank=True)
    current_zone = models.ForeignKey('parking.Zone', on_delete=models.SET_NULL, null=True, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    class Meta:
        verbose_name = 'Officer Status'
        verbose_name_plural = 'Officer Statuses'
        indexes = [
            models.Index(fields=['is_online'], name='enf_stat_online_idx'),
            models.Index(fields=['current_zone'], name='enf_stat_zone_idx'),
        ]

    def __str__(self):
        status_text = 'Online' if self.is_online else 'Offline'
        return f"{self.officer.full_name} - {status_text}"

class QRCodeScan(BaseModel):
    """Log of QR codes scanned by officers"""
    officer = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='qr_scans')
    parking_session = models.ForeignKey('parking.ParkingSession', on_delete=models.CASCADE, 
                                       related_name='qr_scans', verbose_name=_("Parking Session"))
    
    qr_data = models.TextField(verbose_name=_("QR Data"))
    scan_status = models.CharField(
        max_length=20, 
        choices=[
            ('valid', _('Valid')),
            ('invalid', _('Invalid')),
            ('expired', _('Expired')),
            ('already_ended', _('Already Ended')),
        ],
        default='valid',
        verbose_name=_("Scan Status")
    )
    
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    session_ended = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['officer', '-created_at']),
            models.Index(fields=['parking_session', '-created_at']),
            models.Index(fields=['officer'], name='enf_qrcodescan_officer_idx'),
            models.Index(fields=['parking_session'], name='enf_qrcodescan_session_idx'),
            models.Index(fields=['created_at'], name='enf_qrcodescan_created_at_idx'),
        ]

    def __str__(self):
        return f"QR Scan by {self.officer.phone} - {self.parking_session.vehicle.license_plate}"


class GuestParkingSession(RegionalModel, BaseModel):
    """Parking sessions for non-app users created by officers"""
    license_plate = models.CharField(max_length=20, db_index=True, verbose_name=_("License Plate"))
    driver_name = models.CharField(max_length=100, verbose_name=_("Driver Name"))
    driver_phone = models.CharField(max_length=20, null=True, blank=True, verbose_name=_("Driver Phone"))
    
    zone = models.ForeignKey('parking.Zone', on_delete=models.CASCADE, related_name='guest_sessions', verbose_name=_("Zone"))
    parking_slot = models.ForeignKey('parking.ParkingSlot', on_delete=models.SET_NULL, null=True, blank=True, verbose_name=_("Parking Slot"))
    officer = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='created_guest_sessions', verbose_name=_("Officer"))
    
    start_time = models.DateTimeField(db_index=True, verbose_name=_("Start Time"))
    planned_end_time = models.DateTimeField(verbose_name=_("Planned End Time"))
    actual_end_time = models.DateTimeField(null=True, blank=True, verbose_name=_("Actual End Time"))
    
    estimated_cost = models.DecimalField(max_digits=12, decimal_places=2, verbose_name=_("Estimated Cost"))
    final_cost = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, verbose_name=_("Final Cost"))
    
    payment_status = models.CharField(
        max_length=20,
        choices=[
            ('pending', _('Pending Payment')),
            ('completed', _('Payment Completed')),
            ('failed', _('Payment Failed')),
            ('free', _('Free Session')),
        ],
        default='pending',
        db_index=True,
        verbose_name=_("Payment Status")
    )
    
    payment_transaction = models.OneToOneField(
        'payments.Transaction',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='guest_parking_session',
        verbose_name=_("Payment Transaction")
    )
    
    status = models.CharField(
        max_length=20,
        choices=[
            ('active', _('Active')),
            ('ended', _('Ended')),
            ('overdue', _('Overdue')),
            ('cancelled', _('Cancelled')),
        ],
        default='active',
        db_index=True,
        verbose_name=_("Status")
    )
    
    notes = models.TextField(blank=True, verbose_name=_("Officer Notes"))

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['license_plate'], name='enf_guest_plate_idx'),
            models.Index(fields=['officer', '-created_at'], name='enf_guest_off_cr_idx'),
            models.Index(fields=['zone', '-created_at'], name='enf_guest_zone_cr_idx'),
            models.Index(fields=['status'], name='enf_guest_status_idx'),
            models.Index(fields=['payment_status'], name='enf_guest_pay_idx'),
            models.Index(fields=['start_time'], name='enf_guest_start_idx'),
            models.Index(fields=['planned_end_time'], name='enf_guest_end_idx'),
        ]
    
    def __str__(self):
        return f"Guest Session: {self.license_plate} ({self.driver_name}) - {self.zone.name}"
    
    @property
    def is_overdue(self):
        """Check if session is overdue"""
        from django.utils import timezone
        from apps.common.constants import ParkingStatus
        return self.status == ParkingStatus.ACTIVE and timezone.now() > self.planned_end_time