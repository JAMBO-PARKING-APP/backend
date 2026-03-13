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
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    radius_meters = models.IntegerField(default=100)
    zone_image = models.ImageField(upload_to='zones/images/', null=True, blank=True, 
                                  help_text=_("Photo of the actual parking zone"))
    diagram_image = models.ImageField(upload_to='zones/diagrams/', null=True, blank=True,
                                     help_text=_("Parking layout diagram (like airplane seat map)"))
    diagram_width = models.IntegerField(default=800, help_text=_("Diagram width in pixels"))
    diagram_height = models.IntegerField(default=600, help_text=_("Diagram height in pixels"))
    
    def save(self, *args, **kwargs):
        is_new = self._state.adding
        super().save(*args, **kwargs)
        
        if self.total_slots > 0:
            current_slots = self.slots.count()
            if current_slots < self.total_slots:
                new_slots = []
                for i in range(current_slots + 1, self.total_slots + 1):
                    prefix = self.code or self.name[:3].upper()
                    slot_code = f"{prefix}-{i:03d}"
                    
                    if not ParkingSlot.objects.filter(zone=self, slot_code=slot_code).exists():
                        new_slots.append(ParkingSlot(
                            zone=self,
                            slot_code=slot_code,
                            status=SlotStatus.AVAILABLE
                        ))
                
                if new_slots:
                    ParkingSlot.objects.bulk_create(new_slots)

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
        """Calculate available slots based on active sessions, confirmed reservations and capacity"""
        now = timezone.now()
        confirmed_res = self.reservations.filter(
            status='confirmed',
            reserved_from__lte=now,
            reserved_until__gt=now
        ).count()
        return max(0, self.capacity - self.active_sessions_count - confirmed_res)

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
        indexes = [
            models.Index(fields=['country'], name='prk_zone_cntry_idx'),
            models.Index(fields=['created_at'], name='prk_zone_created_idx'),
            models.Index(fields=['code'], name='prk_zone_code_idx'),
            models.Index(fields=['is_active', 'country'], name='prk_zone_act_cnt_idx'),
        ]

class ParkingSlot(BaseModel):
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name='slots')
    slot_code = models.CharField(max_length=10)
    status = models.CharField(max_length=20, choices=SlotStatus.choices, default=SlotStatus.AVAILABLE, db_index=True)
    diagram_x = models.IntegerField(default=0, help_text=_("X position on diagram"))
    diagram_y = models.IntegerField(default=0, help_text=_("Y position on diagram"))
    diagram_width = models.IntegerField(default=40, help_text=_("Slot width on diagram"))
    diagram_height = models.IntegerField(default=80, help_text=_("Slot height on diagram"))
    diagram_rotation = models.IntegerField(default=0, help_text=_("Rotation angle in degrees"))
    slot_type = models.CharField(max_length=20, choices=[
        ('regular', _('Regular')),
        ('disabled', _('Disabled')),
        ('electric', _('Electric Vehicle')),
        ('compact', _('Compact')),
        ('motorcycle', _('Motorcycle')),
    ], default='regular', db_index=True)
    
    class Meta:
        unique_together = ['zone', 'slot_code']
        indexes = [
            models.Index(fields=['zone'], name='prk_slot_zone_idx'),
            models.Index(fields=['zone', 'status'], name='prk_slot_z_stat_idx'),
            models.Index(fields=['slot_type'], name='prk_slot_type_idx'),
            models.Index(fields=['zone', 'slot_type', 'status'], name='prk_slot_z_t_s_idx'),
        ]

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

class ParkingSession(RegionalModel, BaseModel):
    vehicle = models.ForeignKey('accounts.Vehicle', on_delete=models.CASCADE, related_name='parking_sessions')
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name='sessions')
    parking_slot = models.ForeignKey(ParkingSlot, on_delete=models.SET_NULL, null=True, blank=True)
    
    start_time = models.DateTimeField(default=timezone.now, db_index=True)
    planned_end_time = models.DateTimeField()
    actual_end_time = models.DateTimeField(null=True, blank=True, db_index=True)
    
    status = models.CharField(max_length=20, choices=ParkingStatus.choices, default=ParkingStatus.ACTIVE, db_index=True)
    estimated_cost = models.DecimalField(max_digits=12, decimal_places=2)
    final_cost = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)

    @property
    def is_overdue(self):
        """Check if session is currently active but passed planned end time"""
        if self.status != ParkingStatus.ACTIVE:
            return False
        return timezone.now() > self.planned_end_time

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
            models.Index(fields=['vehicle'], name='prk_sess_veh_idx'),
            models.Index(fields=['actual_end_time'], name='prk_sess_end_idx'),
            models.Index(fields=['created_at'], name='prk_sess_created_idx'),
            models.Index(fields=['status', 'planned_end_time'], name='prk_sess_stat_end_idx'),
            models.Index(fields=['start_time', 'status'], name='prk_sess_start_stat_idx'),
            models.Index(fields=['planned_end_time'], name='prk_sess_plan_end_idx'),
        ]

    def __str__(self):
        return f"{self.vehicle.license_plate} - {self.zone.name}"

        if self.parking_slot and self.parking_slot.zone != self.zone:
            raise ValidationError(_("Parking slot must belong to the selected zone"))

    def save(self, *args, **kwargs):
        if self.zone and not self.country:
            self.country = self.zone.country
        super().save(*args, **kwargs)

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
        
        refund_amount = Decimal('0')
        if self.estimated_cost > self.final_cost:
            refund_amount = self.estimated_cost - self.final_cost
            
            from django.db.models import F
            user = self.vehicle.user
            user.adjust_wallet_balance(refund_amount)
            
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
            
            notify_wallet_refund(wallet_tx, self)
        
        self.status = ParkingStatus.COMPLETED
        
        try:
            from apps.rewards.tasks import award_loyalty_points_task
            award_loyalty_points_task.delay(
                user_id=str(self.vehicle.user.id),
                amount_spent=float(self.final_cost),
                description=f"Parking at {self.zone.name}",
                reference_id=str(self.id)
            )
        except Exception as e:
            print(f"Error scheduling point awarding: {e}")

        if self.parking_slot:
            self.parking_slot.status = SlotStatus.AVAILABLE
            self.parking_slot.save()
        
        self.save()

        from apps.notifications.notification_triggers import notify_parking_ended, notify_officers_session_event
        notify_parking_ended(self)
        notify_officers_session_event(self, 'session_ended')
        
        return True

    def cancel_session(self):
        """Cancel an active session and calculate refund"""
        if self.status != ParkingStatus.ACTIVE:
            raise ValidationError(_("Only active sessions can be cancelled"))
            
        now = timezone.now()
        if now >= self.planned_end_time:
            self.end_session()
            return 0
            
        total_planned_seconds = (self.planned_end_time - self.start_time).total_seconds()
        remaining_seconds = (self.planned_end_time - now).total_seconds()
        refund_amount = (Decimal(str(remaining_seconds)) / Decimal(str(total_planned_seconds))) * self.estimated_cost
        refund_amount = refund_amount.quantize(Decimal('0.01'))
        
        self.actual_end_time = now
        self.final_cost = self.estimated_cost - refund_amount
        self.status = ParkingStatus.CANCELLED
        
        if self.parking_slot:
            self.parking_slot.status = SlotStatus.AVAILABLE
            self.parking_slot.save()
            
        self.save()
        
        if refund_amount > 0:
            user = self.vehicle.user
            user.adjust_wallet_balance(refund_amount)
            
            from apps.payments.models import WalletTransaction
            wallet_tx = WalletTransaction.objects.create(
                user=user,
                amount=refund_amount,
                transaction_type='refund',
                description=f"Refund for cancelled session at {self.zone.name}",
                parking_session=self,
                status='completed'
            )
            
            from apps.notifications.notification_triggers import notify_wallet_refund
            notify_wallet_refund(wallet_tx, self)
            
        return refund_amount

    @property
    def qr_code_data(self):
        """Generate a detailed verification string for QR code"""
        from apps.common.utils import get_user_local_time
        driver = self.vehicle.user
        local_start = get_user_local_time(driver, self.start_time)
        local_expiry = get_user_local_time(driver, self.planned_end_time)
        
        start = local_start.strftime("%Y-%m-%d %H:%M")
        expiry = local_expiry.strftime("%Y-%m-%d %H:%M")
        
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
    STATUS_CHOICES = [
        ('pending_payment', _('Pending Payment')),
        ('confirmed', _('Confirmed')),
        ('cancelled', _('Cancelled')),
        ('completed', _('Completed')),
        ('expired', _('Expired')),
    ]

    vehicle = models.ForeignKey('accounts.Vehicle', on_delete=models.CASCADE, related_name='reservations')
    zone = models.ForeignKey(Zone, on_delete=models.CASCADE, related_name='reservations')
    parking_slot = models.ForeignKey(ParkingSlot, on_delete=models.SET_NULL, null=True, blank=True)
    
    reserved_from = models.DateTimeField(db_index=True)
    reserved_until = models.DateTimeField(db_index=True)
    cost = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending_payment', db_index=True)
    payment_reference = models.CharField(max_length=100, blank=True, null=True, help_text=_("Payment transaction reference"))
    is_active = models.BooleanField(default=True)

    class Meta:
        indexes = [
            models.Index(fields=['zone', 'status', 'reserved_from', 'reserved_until']),
            models.Index(fields=['vehicle', 'status']),
            models.Index(fields=['reserved_from'], name='prk_res_from_idx'),
            models.Index(fields=['reserved_until'], name='prk_res_until_idx'),
            models.Index(fields=['created_at'], name='prk_res_created_idx'),
        ]

    def __str__(self):
        return f"{self.vehicle.license_plate} - {self.zone.name} ({self.status})"

    def save(self, *args, **kwargs):
        if self.status in ['cancelled', 'expired', 'completed']:
            if self.parking_slot and self.parking_slot.status != SlotStatus.AVAILABLE:
                self.parking_slot.status = SlotStatus.AVAILABLE
                self.parking_slot.save(update_fields=['status'])
        super().save(*args, **kwargs)