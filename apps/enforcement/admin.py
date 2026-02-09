from django.contrib import admin
from .models import Violation, ViolationEvidence, OfficerLog

@admin.register(Violation)
class ViolationAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'officer', 'violation_type', 'fine_amount', 'is_paid', 'created_at')
    list_filter = ('violation_type', 'is_paid', 'zone')
    search_fields = ('vehicle__license_plate', 'officer__first_name', 'officer__last_name')
    readonly_fields = ('created_at',)

@admin.register(ViolationEvidence)
class ViolationEvidenceAdmin(admin.ModelAdmin):
    list_display = ('violation', 'description', 'created_at')
    readonly_fields = ('created_at',)

@admin.register(OfficerLog)
class OfficerLogAdmin(admin.ModelAdmin):
    list_display = ('officer', 'action', 'created_at')
    list_filter = ('action',)
    search_fields = ('officer__first_name', 'officer__last_name')
    readonly_fields = ('created_at',)