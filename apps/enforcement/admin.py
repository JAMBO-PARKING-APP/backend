from django.contrib import admin
from .models import Violation, ViolationEvidence, OfficerLog, OfficerStatus, QRCodeScan, GuestParkingSession

@admin.register(Violation)
class ViolationAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'officer', 'violation_type', 'fine_amount', 'is_paid', 'created_at')
    list_filter = ('violation_type', 'is_paid', 'zone')
    search_fields = ('vehicle__license_plate', 'officer__first_name', 'officer__last_name', 'officer__phone')
    autocomplete_fields = ['vehicle', 'officer', 'zone']
    readonly_fields = ('created_at',)

@admin.register(ViolationEvidence)
class ViolationEvidenceAdmin(admin.ModelAdmin):
    list_display = ('violation', 'description', 'created_at')
    readonly_fields = ('created_at',)

@admin.register(OfficerLog)
class OfficerLogAdmin(admin.ModelAdmin):
    list_display = ('officer', 'action', 'created_at')
    list_filter = ('action',)
    search_fields = ('officer__first_name', 'officer__last_name', 'officer__phone')
    autocomplete_fields = ['officer']
    readonly_fields = ('created_at',)

@admin.register(OfficerStatus)
class OfficerStatusAdmin(admin.ModelAdmin):
    list_display = ('officer', 'is_online', 'went_online_at', 'went_offline_at', 'current_zone')
    list_filter = ('is_online',)
    search_fields = ('officer__first_name', 'officer__last_name', 'officer__phone')
    autocomplete_fields = ['officer', 'current_zone']
    readonly_fields = ('created_at', 'updated_at')

@admin.register(QRCodeScan)
class QRCodeScanAdmin(admin.ModelAdmin):
    list_display = ('officer', 'parking_session', 'scan_status', 'session_ended', 'created_at')
    list_filter = ('scan_status', 'session_ended')
    search_fields = ('officer__first_name', 'officer__last_name', 'officer__phone', 'parking_session__vehicle__license_plate')
    autocomplete_fields = ['officer', 'parking_session']
    readonly_fields = ('created_at', 'updated_at')

@admin.register(GuestParkingSession)
class GuestParkingSessionAdmin(admin.ModelAdmin):
    list_display = ('license_plate', 'driver_name', 'zone', 'officer', 'status', 'start_time', 'planned_end_time', 'estimated_cost')
    list_filter = ('status', 'zone', 'start_time')
    search_fields = ('license_plate', 'driver_name', 'driver_phone', 'officer__first_name', 'officer__last_name')
    autocomplete_fields = ['zone', 'officer', 'parking_slot']
    readonly_fields = ('created_at', 'updated_at', 'start_time')
    fieldsets = (
        ('Vehicle & Driver Info', {
            'fields': ('license_plate', 'driver_name', 'driver_phone')
        }),
        ('Parking Details', {
            'fields': ('zone', 'parking_slot', 'start_time', 'planned_end_time', 'actual_end_time')
        }),
        ('Cost & Status', {
            'fields': ('estimated_cost', 'final_cost', 'status')
        }),
        ('Officer & Notes', {
            'fields': ('officer', 'notes')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )