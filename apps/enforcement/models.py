from django.db import models
from apps.common.models import BaseModel
from apps.common.constants import ViolationType

from django.utils.translation import gettext_lazy as _

class Violation(BaseModel):
    vehicle = models.ForeignKey('accounts.Vehicle', on_delete=models.CASCADE, related_name='violations', verbose_name=_("Vehicle"))
    officer = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='issued_violations', verbose_name=_("Officer"))
    zone = models.ForeignKey('parking.Zone', on_delete=models.CASCADE, related_name='violations', verbose_name=_("Zone"))
    parking_session = models.ForeignKey('parking.ParkingSession', on_delete=models.SET_NULL, 
                                       null=True, blank=True, related_name='violations', verbose_name=_("Parking Session"))
    
    violation_type = models.CharField(max_length=20, choices=ViolationType.choices, verbose_name=_("Violation Type"))
    description = models.TextField(verbose_name=_("Description"))
    fine_amount = models.DecimalField(max_digits=8, decimal_places=2, verbose_name=_("Fine Amount"))
    
    # Location data
    latitude = models.DecimalField(max_digits=9, decimal_places=6, verbose_name=_("Latitude"))
    longitude = models.DecimalField(max_digits=9, decimal_places=6, verbose_name=_("Longitude"))
    
    is_paid = models.BooleanField(default=False, verbose_name=_("Is Paid"))
    paid_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Paid At"))

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
    action = models.CharField(max_length=50)  # 'check_plate', 'issue_violation', etc.
    details = models.JSONField(default=dict)
    
    # Location data
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    def __str__(self):
        return f"{self.officer.full_name} - {self.action}"