from rest_framework import serializers
from .models import Zone, ParkingSlot, ParkingSession, Reservation

class ParkingSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParkingSlot
        fields = ['id', 'slot_code', 'status', 'slot_type', 'diagram_x', 'diagram_y', 
                  'diagram_width', 'diagram_height', 'diagram_rotation']

class ZoneDetailSerializer(serializers.ModelSerializer):
    available_slots = serializers.SerializerMethodField()
    occupied_slots = serializers.SerializerMethodField()
    occupancy_rate = serializers.SerializerMethodField()
    slots = ParkingSlotSerializer(many=True, read_only=True)
    
    class Meta:
        model = Zone
        fields = ['id', 'name', 'description', 'hourly_rate', 'max_duration_hours',
                  'total_slots', 'available_slots', 'occupied_slots', 'occupancy_rate',
                  'latitude', 'longitude', 'radius_meters', 'zone_image', 'diagram_image',
                  'diagram_width', 'diagram_height', 'slots', 'created_at']
    
    def get_available_slots(self, obj):
        return obj.available_slots_count
    
    def get_occupied_slots(self, obj):
        return obj.total_slots_count - obj.available_slots_count
    
    def get_occupancy_rate(self, obj):
        return round(obj.occupancy_rate, 2)

class ZoneListSerializer(serializers.ModelSerializer):
    available_slots = serializers.SerializerMethodField()
    occupancy_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = Zone
        fields = ['id', 'name', 'description', 'hourly_rate', 'max_duration_hours',
                  'total_slots', 'available_slots', 'occupancy_rate', 'latitude', 
                  'longitude', 'radius_meters', 'zone_image', 'created_at']
    
    def get_available_slots(self, obj):
        return obj.available_slots_count
    
    def get_occupancy_rate(self, obj):
        return round(obj.occupancy_rate, 2)

class ParkingSessionSerializer(serializers.ModelSerializer):
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    slot_code = serializers.CharField(source='parking_slot.slot_code', read_only=True)
    
    class Meta:
        model = ParkingSession
        fields = ['id', 'vehicle_plate', 'zone_name', 'slot_code', 'start_time',
                  'planned_end_time', 'actual_end_time', 'status', 'estimated_cost',
                  'final_cost', 'qr_code_data', 'created_at']
        read_only_fields = ['id', 'start_time', 'created_at']

class StartParkingSerializer(serializers.Serializer):
    vehicle_id = serializers.UUIDField()
    zone_id = serializers.UUIDField()
    slot_id = serializers.UUIDField(required=False)
    duration_hours = serializers.IntegerField(default=1, min_value=1, max_value=24)
    payment_method = serializers.ChoiceField(choices=['wallet', 'pesapal'], default='wallet')

class EndParkingSerializer(serializers.Serializer):
    session_id = serializers.UUIDField()

class ReservationSerializer(serializers.ModelSerializer):
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    
    class Meta:
        model = Reservation
        fields = ['id', 'vehicle_plate', 'zone_name', 'start_time', 'end_time', 
                  'status', 'created_at']
        read_only_fields = ['id', 'created_at']

class CreateReservationSerializer(serializers.Serializer):
    vehicle_id = serializers.UUIDField()
    zone_id = serializers.UUIDField()
    start_time = serializers.DateTimeField()
    end_time = serializers.DateTimeField()
