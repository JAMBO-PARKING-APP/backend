from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from decimal import Decimal
from apps.common.models import BaseModel, RegionalModel
from apps.common.constants import ParkingStatus, SlotStatus

class Zone(RegionalModel, BaseModel):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    hourly_rate = models.DecimalField(max_digits=12, decimal_places=2)
    max_duration_hours = models.IntegerField(default=24)
    total_slots = models.IntegerField(default=0, help_text=_("Total number of parking slots in this zone"))
    code = models.CharField(max_length=20, unique=True, null=True, blank=True, help_text=_("Short unique code for the zone (e.g. JB01)"))
    is_active = models.BooleanField(default=True, db_index=True)
    
    # Geographic boundaries
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    radius_meters = models.IntegerField(default=100)
    
    # Zone images and diagram
    zone_image = models.ImageField(upload_to='zones/images/', null=True, blank=True, 
                                  help_text=_("Photo of the actual parking zone"))
    diagram_image = models.ImageField(upload_to='zones/diagrams/', null=True, blank=True,
                                     help_text=_("Parking layout diagram (like airplane seat map)"))
    
    # Diagram configuration
    diagram_width = models.IntegerField(default=800, help_text=_("Diagram width in pixels"))
    diagram_height = models.IntegerField(default=600, help_text=_("Diagram height in pixels"))

    def __str__(self):
        return self.name

    @property
    def available_slots_count(self):
        return self.slots.filter(status=SlotStatus.AVAILABLE).count()

    @property
    def active_sessions_count(self):
        """Get number of active parking sessions in this zone"""
        return self.sessions.filter(status=ParkingStatus.ACTIVE).count()

    @property
    def available_slots(self):
        """Calculate available slots based on active sessions and capacity"""
        return max(0, self.capacity - self.active_sessions_count)

    @property
    def occupied_slots(self):
        """Calculate occupied slots based on active sessions"""
        return self.active_sessions_count

    @property
    def total_slots_count(self):
        return self.slots.count()

    @property
    def capacity(self):
        """Get the total capacity - either from configured total_slots or actual slot count"""
        if self.total_slots > 0:
            return self.total_slots
        return self.total_slots_count

    @property
    def occupancy_rate(self):
        capacity = self.capacity
        if capacity == 0:
            return 0
        occupied = self.occupied_slots
        return (occupied / capacity) * 100

    class Meta:
        ordering = ['name']

class ParkingSlot(BaseModel):
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name='slots')
    slot_code = models.CharField(max_length=10)  # A1, B2, etc.
    status = models.CharField(max_length=20, choices=SlotStatus.choices, default=SlotStatus.AVAILABLE, db_index=True)
    
    # Position on diagram (coordinates)
    diagram_x = models.IntegerField(default=0, help_text=_("X position on diagram"))
    diagram_y = models.IntegerField(default=0, help_text=_("Y position on diagram"))
    diagram_width = models.IntegerField(default=40, help_text=_("Slot width on diagram"))
    diagram_height = models.IntegerField(default=80, help_text=_("Slot height on diagram"))
    diagram_rotation = models.IntegerField(default=0, help_text=_("Rotation angle in degrees"))
    
    # Slot type and properties
    slot_type = models.CharField(max_length=20, choices=[
        ('regular', _('Regular')),
        ('disabled', _('Disabled')),
        ('electric', _('Electric Vehicle')),
        ('compact', _('Compact')),
        ('motorcycle', _('Motorcycle')),
    ], default='regular', db_index=True)
    
    class Meta:
        unique_together = ['zone', 'slot_code']

    def __str__(self):
        return f"{self.zone.name} - {self.slot_code}"

class ZoneBoundary(BaseModel):
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name='boundaries')
    name = models.CharField(max_length=50)
    points = models.JSONField(help_text=_("Array of {x, y} coordinates defining the boundary"))
    boundary_type = models.CharField(max_length=20, choices=[
        ('outer', _('Outer Boundary')),
        ('inner', _('Inner Boundary')),
        ('restricted', _('Restricted Area')),
    ], default='outer')
    color = models.CharField(max_length=7, default='#007bff')
    
    def __str__(self):
        return f"{self.zone.name} - {self.name}"

class ZoneEntrance(BaseModel):
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name='entrances')
    name = models.CharField(max_length=50)
    diagram_x = models.IntegerField()
    diagram_y = models.IntegerField()
    width = models.IntegerField(default=60)
    height = models.IntegerField(default=20)
    entrance_type = models.CharField(max_length=20, choices=[
        ('entry', _('Entry Only')),
        ('exit', _('Exit Only')),
        ('both', _('Entry/Exit')),
    ], default='both')
    
    def __str__(self):
        return f"{self.zone.name} - {self.name}"

class DrivePath(BaseModel):
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name='drive_paths')
    name = models.CharField(max_length=50)
    points = models.JSONField(help_text=_("Array of {x, y} coordinates defining the path"))
    width = models.IntegerField(default=30, help_text=_("Path width in pixels"))
    path_type = models.CharField(max_length=20, choices=[
        ('main', _('Main Drive')),
        ('lane', _('Parking Lane')),
        ('oneway', _('One Way')),
    ], default='main')
    color = models.CharField(max_length=7, default='#6c757d')
    
    def __str__(self):
        return f"{self.zone.name} - {self.name}"

class ParkingSession(BaseModel):
    vehicle = models.ForeignKey('accounts.Vehicle', on_delete=models.CASCADE, related_name='parking_sessions')
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name='sessions')
    parking_slot = models.ForeignKey(ParkingSlot, on_delete=models.SET_NULL, null=True, blank=True)
    
    start_time = models.DateTimeField(default=timezone.now, db_index=True)
    planned_end_time = models.DateTimeField()
    actual_end_time = models.DateTimeField(null=True, blank=True, db_index=True)
    
    status = models.CharField(max_length=20, choices=ParkingStatus.choices, default=ParkingStatus.ACTIVE)
    estimated_cost = models.DecimalField(max_digits=12, decimal_places=2)
    final_cost = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['vehicle'],
                condition=models.Q(status=ParkingStatus.ACTIVE),
                name='one_active_session_per_vehicle'
            )
        ]
        indexes = [
            models.Index(fields=['vehicle_id', 'status']),
            models.Index(fields=['status', 'start_time']),
            models.Index(fields=['zone_id', 'status']),
        ]

    def __str__(self):
        return f"{self.vehicle.license_plate} - {self.zone.name}"

    def clean(self):
        if self.parking_slot and self.parking_slot.zone != self.zone:
            raise ValidationError(_("Parking slot must belong to the selected zone"))

    @property
    def duration_minutes(self):
        end_time = self.actual_end_time or timezone.now()
        return int((end_time - self.start_time).total_seconds() / 60)

    def calculate_cost(self):
        """
        Calculate cost using decimal hours, allow sub-hour durations with a minimum
        of 0.25 hours (15 minutes).
        """
        end_time = self.actual_end_time or timezone.now()
        duration_seconds = (end_time - self.start_time).total_seconds()
        duration_hours = Decimal(str(duration_seconds / 3600))
        if duration_hours < Decimal('0.25'):
            duration_hours = Decimal('0.25')

        cost = (duration_hours * self.zone.hourly_rate).quantize(Decimal('0.01'))
        return cost

    def end_session(self):
        from decimal import Decimal
        from apps.payments.models import WalletTransaction
        from apps.notifications.notification_triggers import notify_wallet_refund
        
        self.actual_end_time = timezone.now()
        self.final_cost = self.calculate_cost()
        
        # Calculate refund for unused time
        refund_amount = Decimal('0')
        if self.estimated_cost > self.final_cost:
            refund_amount = self.estimated_cost - self.final_cost
            
            # Credit wallet
            user = self.vehicle.user
            user.wallet_balance += refund_amount
            user.save(update_fields=['wallet_balance'])
            
            # Create wallet transaction record
            wallet_tx = WalletTransaction.objects.create(
                user=user,
                amount=refund_amount,
                transaction_type='refund',
                description=f'Refund for early session end at {self.zone.name}',
                status='completed',
                parking_session=self,
                metadata={
                    'session_id': str(self.id),
                    'estimated_cost': str(self.estimated_cost),
                    'final_cost': str(self.final_cost),
                }
            )
            
            # Send refund notification
            notify_wallet_refund(wallet_tx, self)
        
        self.status = ParkingStatus.COMPLETED
        
        if self.parking_slot:
            self.parking_slot.status = SlotStatus.AVAILABLE
            self.parking_slot.save()
        
        self.save()

    def cancel_session(self):
        """Cancel an active session and calculate refund"""
        if self.status != ParkingStatus.ACTIVE:
            raise ValidationError(_("Only active sessions can be cancelled"))
            
        now = timezone.now()
        if now >= self.planned_end_time:
            # Session already effectively finished
            self.end_session()
            return 0
            
        # Calculate remaining time and refund
        total_planned_seconds = (self.planned_end_time - self.start_time).total_seconds()
        remaining_seconds = (self.planned_end_time - now).total_seconds()
        
        # Simple proportional refund based on estimated cost
        refund_amount = (Decimal(str(remaining_seconds)) / Decimal(str(total_planned_seconds))) * self.estimated_cost
        refund_amount = refund_amount.quantize(Decimal('0.01'))
        
        self.actual_end_time = now
        self.final_cost = self.estimated_cost - refund_amount
        self.status = ParkingStatus.CANCELLED
        
        if self.parking_slot:
            self.parking_slot.status = SlotStatus.AVAILABLE
            self.parking_slot.save()
            
        self.save()
        return refund_amount

    @property
    def qr_code_data(self):
        """Generate a detailed verification string for QR code"""
        driver = self.vehicle.user
        start = self.start_time.strftime("%Y-%m-%d %H:%M")
        expiry = self.planned_end_time.strftime("%Y-%m-%d %H:%M")
        
        data = [
            "JAMBO PARK VERIFIED PASS",
            f"ID: {self.id}",
            f"Driver: {driver.full_name}",
            f"Phone: {driver.phone}",
            f"Vehicle: {self.vehicle.license_plate}",
            f"Zone: {self.zone.name}",
            f"Started: {start}",
            f"Expires: {expiry}",
            f"Status: {self.status.upper()}",
        ]
        return "\r\n".join(data)

class Reservation(BaseModel):
    vehicle = models.ForeignKey('accounts.Vehicle', on_delete=models.CASCADE, related_name='reservations')
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name='reservations')
    parking_slot = models.ForeignKey(ParkingSlot, on_delete=models.SET_NULL, null=True, blank=True)
    
    reserved_from = models.DateTimeField()
    reserved_until = models.DateTimeField()
    cost = models.DecimalField(max_digits=12, decimal_places=2)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.vehicle.license_plate} - {self.zone.name} ({self.reserved_from})"