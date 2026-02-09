from django.contrib import admin
from .models import Zone, ParkingSlot, ParkingSession, Reservation

@admin.register(Zone)
class ZoneAdmin(admin.ModelAdmin):
    list_display = ('name', 'hourly_rate', 'available_slots_count', 'is_active')
    list_filter = ('is_active',)
    search_fields = ('name',)

@admin.register(ParkingSlot)
class ParkingSlotAdmin(admin.ModelAdmin):
    list_display = ('zone', 'slot_code', 'status')
    list_filter = ('status', 'zone')
    search_fields = ('slot_code', 'zone__name')

@admin.register(ParkingSession)
class ParkingSessionAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'zone', 'start_time', 'status', 'final_cost')
    list_filter = ('status', 'zone')
    search_fields = ('vehicle__license_plate',)
    readonly_fields = ('duration_minutes',)

@admin.register(Reservation)
class ReservationAdmin(admin.ModelAdmin):
    list_display = ('vehicle', 'zone', 'reserved_from', 'reserved_until', 'is_active')
    list_filter = ('is_active', 'zone')
    search_fields = ('vehicle__license_plate',)