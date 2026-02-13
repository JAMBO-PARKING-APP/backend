from django.db import models
from apps.common.models import BaseModel
from apps.common.constants import ViolationType
from django.utils import timezone

from django.utils.translation import gettext_lazy as _

class Violation(BaseModel):
    vehicle = models.ForeignKey('accounts.Vehicle', on_delete=models.CASCADE, related_name='violations', verbose_name=_("Vehicle"))
    officer = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='issued_violations', verbose_name=_("Officer"))
    zone = models.ForeignKey('parking.Zone', on_delete=models.CASCADE, related_name='violations', verbose_name=_("Zone"))
    parking_session = models.ForeignKey('parking.ParkingSession', on_delete=models.SET_NULL, 
                                       null=True, blank=True, related_name='violations', verbose_name=_("Parking Session"))
    
    violation_type = models.CharField(max_length=20, choices=ViolationType.choices, verbose_name=_("Violation Type"), db_index=True)
    description = models.TextField(verbose_name=_("Description"))
    fine_amount = models.DecimalField(max_digits=8, decimal_places=2, verbose_name=_("Fine Amount"))
    
    # Location data
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

class ViolationEvidence(BaseModel):
    violation = models.ForeignKey(Violation, on_delete=models.CASCADE, related_name='evidence')
    image = models.ImageField(upload_to='violations/')
    description = models.CharField(max_length=200, blank=True)

    def __str__(self):
        return f"Evidence for {self.violation}"

class OfficerLog(BaseModel):
    officer = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='activity_logs')
    action = models.CharField(max_length=50)  # 'check_plate', 'issue_violation', 'qr_scan', 'online', 'offline'
    details = models.JSONField(default=dict)
    
    # Location data
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
    
    # Location data
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
    
    # Location data
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    
    # Whether officer ended the session from this scan
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