from django.contrib import admin
from apps.common.admin_mixins import RegionalAdminMixin
from .models import Zone, ParkingSlot, ParkingSession, Reservation, ZoneApplication, ApplicationStatus, ZoneType

class ParkingSlotInline(admin.TabularInline):
    model = ParkingSlot
    extra = 0
    fields = ('slot_code', 'status', 'slot_type')
    readonly_fields = ('status',)

@admin.register(ZoneApplication)
class ZoneApplicationAdmin(RegionalAdminMixin, admin.ModelAdmin):
    list_display = ('proposed_name', 'user', 'status', 'total_slots', 'proposed_hourly_rate', 'created_at')
    list_filter = ('status', 'country')
    search_fields = ('proposed_name', 'user__phone', 'user__full_name')
    readonly_fields = ('created_at', 'updated_at', 'created_zone')
    actions = ['approve_applications']

    def approve_applications(self, request, queryset):
        for app in queryset.filter(status=ApplicationStatus.PENDING):
            self._do_approve(app)
        self.message_user(request, "Selected applications have been approved and zones created.")
    approve_applications.short_description = "Approve selected applications"

    def save_model(self, request, obj, form, change):
        if change and obj.status == ApplicationStatus.APPROVED and not obj.created_zone:
            # Status changed to approved in the form
            self._do_approve(obj)
        super().save(request, obj, form, change)

    def _do_approve(self, application):
        if application.created_zone:
            return
            
        # Create the actual zone
        zone = Zone.objects.create(
            name=application.proposed_name,
            address=application.address,
            latitude=application.latitude,
            longitude=application.longitude,
            hourly_rate=application.proposed_hourly_rate,
            total_slots=application.total_slots,
            owner=application.user,
            zone_type=ZoneType.PRIVATE,
            country=application.country,
            phone_code=application.phone_code,
            currency=application.currency,
            is_active=True
        )
        
        application.created_zone = zone
        application.status = ApplicationStatus.APPROVED
        application.save()

@admin.register(Zone)
class ZoneAdmin(RegionalAdminMixin, admin.ModelAdmin):
    list_display = ('name', 'zone_type', 'owner', 'hourly_rate', 'total_slots', 'available_slots_count', 'is_active')
    list_filter = ('zone_type', 'country', 'is_active')
    search_fields = ('name', 'code', 'owner__full_name')
    inlines = [ParkingSlotInline]

@admin.register(ParkingSlot)
class ParkingSlotAdmin(admin.ModelAdmin):
    list_display = ('zone', 'slot_code', 'status')
    list_filter = ('status', 'zone')
    search_fields = ('slot_code', 'zone__name')

@admin.register(ParkingSession)
class ParkingSessionAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'zone', 'get_zone_type', 'start_time', 'status', 'final_cost')
    list_filter = ('status', 'zone__zone_type', 'zone')
    search_fields = ('vehicle__license_plate', 'zone__name', 'zone__owner__full_name')
    readonly_fields = ('duration_minutes',)

    def get_zone_type(self, obj):
        return obj.zone.zone_type
    get_zone_type.short_description = 'Zone Type'

@admin.register(Reservation)
class ReservationAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'zone', 'reserved_from', 'reserved_until', 'status', 'payment_reference')
    list_filter = ('status', 'zone', 'reserved_from')
    search_fields = ('vehicle__license_plate', 'payment_reference')
    readonly_fields = ('created_at',)