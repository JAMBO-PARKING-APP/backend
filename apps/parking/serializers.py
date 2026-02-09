from rest_framework import serializers
from .models import Zone, ParkingSlot, ParkingSession, Reservation

class ParkingSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParkingSlot
        fields = ('id', 'slot_code', 'status')

class ZoneSerializer(serializers.ModelSerializer):
    available_slots_count = serializers.ReadOnlyField()
    slots = ParkingSlotSerializer(many=True, read_only=True)

    class Meta:
        model = Zone
        fields = ('id', 'name', 'description', 'hourly_rate', 'max_duration_hours', 
                 'available_slots_count', 'slots')

class ParkingSessionSerializer(serializers.ModelSerializer):
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    duration_minutes = serializers.ReadOnlyField()
    slot_code = serializers.CharField(source='parking_slot.slot_code', read_only=True)

    class Meta:
        model = ParkingSession
        fields = ('id', 'vehicle_plate', 'zone_name', 'slot_code', 'start_time', 
                 'planned_end_time', 'actual_end_time', 'status', 'estimated_cost', 
                 'final_cost', 'duration_minutes')

class ReservationSerializer(serializers.ModelSerializer):
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)

    class Meta:
        model = Reservation
        fields = ('id', 'vehicle_plate', 'zone_name', 'reserved_from', 'reserved_until', 
                 'cost', 'is_active')