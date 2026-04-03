from rest_framework import serializers
from .models import Zone, ParkingSlot, ParkingSession, Reservation

class ParkingSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParkingSlot
        fields = ('id', 'slot_code', 'status')
        read_only_fields = ('id', 'slot_code')

class ZoneSerializer(serializers.ModelSerializer):
    available_slots_count = serializers.ReadOnlyField()
    slots = ParkingSlotSerializer(many=True, read_only=True)
    country_name = serializers.CharField(source='country.name', read_only=True)

    class Meta:
        model = Zone
        fields = ('id', 'name', 'code', 'description', 'hourly_rate', 'max_duration_hours', 
                 'total_slots', 'is_active', 'latitude', 'longitude', 'radius_meters',
                 'country', 'country_name', 'google_maps_url', 'available_slots_count', 
                 'slots', 'zone_image', 'diagram_image')

class ParkingSessionSerializer(serializers.ModelSerializer):
    hourly_rate = serializers.DecimalField(source='zone.hourly_rate', max_digits=12, decimal_places=2, read_only=True)
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    slot_code = serializers.CharField(source='parking_slot.slot_code', read_only=True)
    duration_minutes = serializers.ReadOnlyField()

    class Meta:
        model = ParkingSession
        fields = ('id', 'vehicle_plate', 'zone_name', 'slot_code', 'start_time', 
                 'planned_end_time', 'actual_end_time', 'status', 'estimated_cost', 
                 'final_cost', 'duration_minutes', 'hourly_rate')

class ReservationSerializer(serializers.ModelSerializer):
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)

    class Meta:
        model = Reservation
        fields = ('id', 'vehicle_plate', 'zone_name', 'reserved_from', 'reserved_until', 
                 'cost', 'is_active')

from .models import ZoneApplication

class ZoneApplicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = ZoneApplication
        fields = ('id', 'proposed_name', 'address', 'latitude', 'longitude', 
                 'total_slots', 'proposed_hourly_rate', 'operating_hours', 
                 'parking_surface', 'has_security', 'has_cctv', 'access_instructions',
                 'status', 'documents', 'created_at')
        read_only_fields = ('id', 'status', 'created_at')

class OwnerZoneSerializer(serializers.ModelSerializer):
    available_slots_count = serializers.ReadOnlyField()
    active_sessions_count = serializers.ReadOnlyField()
    
    class Meta:
        model = Zone
        fields = ('id', 'name', 'code', 'description', 'hourly_rate', 'max_duration_hours', 
                 'total_slots', 'is_active', 'latitude', 'longitude', 'commission_rate',
                 'available_slots_count', 'active_sessions_count')
        read_only_fields = ('id', 'commission_rate', 'active_sessions_count', 'available_slots_count')

class OwnerParkingSessionSerializer(serializers.ModelSerializer):
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    is_overdue = serializers.ReadOnlyField()
    
    class Meta:
        model = ParkingSession
        fields = ('id', 'vehicle_plate', 'start_time', 'planned_end_time', 
                 'actual_end_time', 'status', 'estimated_cost', 'final_cost', 'is_overdue')

class OwnerParkingSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParkingSlot
        fields = ('id', 'slot_code', 'status', 'slot_type')
        read_only_fields = ('id', 'slot_code')

class OwnerViolationReportSerializer(serializers.Serializer):
    session_id = serializers.UUIDField(required=True)
    violation_type = serializers.ChoiceField(choices=[('overdue_parking', 'Overdue Parking'), ('other', 'Other')])
    description = serializers.CharField(required=False, allow_blank=True)
    fine_amount = serializers.DecimalField(max_digits=8, decimal_places=2, required=False)