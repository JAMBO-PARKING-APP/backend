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
    capacity = serializers.SerializerMethodField()
    slots = ParkingSlotSerializer(many=True, read_only=True)
    
    class Meta:
        model = Zone
        fields = ['id', 'name', 'description', 'hourly_rate', 'max_duration_hours',
                  'total_slots', 'capacity', 'available_slots', 'occupied_slots', 'occupancy_rate',
                  'latitude', 'longitude', 'radius_meters', 'zone_image', 'diagram_image',
                  'diagram_width', 'diagram_height', 'slots', 'created_at']
    
    def get_available_slots(self, obj):
        return obj.available_slots
    
    def get_occupied_slots(self, obj):
        return obj.occupied_slots
    
    def get_capacity(self, obj):
        return obj.capacity
    
    def get_occupancy_rate(self, obj):
        return round(obj.occupancy_rate, 2)

class ZoneListSerializer(serializers.ModelSerializer):
    available_slots = serializers.SerializerMethodField()
    occupied_slots = serializers.SerializerMethodField()
    occupancy_rate = serializers.SerializerMethodField()
    capacity = serializers.SerializerMethodField()
    
    class Meta:
        model = Zone
        fields = ['id', 'name', 'description', 'hourly_rate', 'max_duration_hours',
                  'total_slots', 'capacity', 'available_slots', 'occupied_slots', 'occupancy_rate', 'latitude', 
                  'longitude', 'radius_meters', 'zone_image', 'created_at']
    
    def get_available_slots(self, obj):
        return obj.available_slots
    
    def get_occupied_slots(self, obj):
        return obj.occupied_slots
    
    def get_capacity(self, obj):
        return obj.capacity
    
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
    duration_hours = serializers.DecimalField(max_digits=10, decimal_places=5, default=1, min_value=0.25, max_value=24)
    payment_method = serializers.ChoiceField(choices=['wallet', 'pesapal'], default='wallet')

class EndParkingSerializer(serializers.Serializer):
    session_id = serializers.UUIDField()

class ReservationSerializer(serializers.ModelSerializer):
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    start_time = serializers.DateTimeField(source='reserved_from', read_only=True)
    end_time = serializers.DateTimeField(source='reserved_until', read_only=True)
    
    class Meta:
        model = Reservation
        fields = ['id', 'vehicle_plate', 'zone_name', 'start_time', 'end_time', 
                  'status', 'cost', 'payment_reference', 'created_at']
        read_only_fields = ['id', 'created_at', 'status', 'cost', 'payment_reference']

class CreateReservationSerializer(serializers.Serializer):
    vehicle_id = serializers.UUIDField()
    zone_id = serializers.UUIDField()
    # Support both old and new field names
    start_time = serializers.DateTimeField(required=False)
    end_time = serializers.DateTimeField(required=False)
    reserved_from = serializers.DateTimeField(required=False)
    reserved_until = serializers.DateTimeField(required=False)
    created_at = serializers.DateTimeField(read_only=True)

    def validate(self, data):
        """Ensure either start_time/end_time OR reserved_from/reserved_until are provided"""
        start = data.get('start_time') or data.get('reserved_from')
        end = data.get('end_time') or data.get('reserved_until')
        
        if not start:
             raise serializers.ValidationError("Start time (reserved_from) is required")
        if not end:
             raise serializers.ValidationError("End time (reserved_until) is required")
             
        return data


# Officer App Serializers
class ZoneSerializer(serializers.ModelSerializer):
    """Simple zone serializer for officer app"""
    active_sessions = serializers.SerializerMethodField()
    
    class Meta:
        model = Zone
        fields = ['id', 'name', 'code', 'total_slots', 'occupied_slots', 
                  'available_slots', 'active_sessions', 'latitude', 'longitude']
    
    def get_active_sessions(self, obj):
        """Get count of active sessions in this zone"""
        from apps.common.constants import ParkingStatus
        return obj.sessions.filter(status=ParkingStatus.ACTIVE).count()


class ParkingSessionDetailSerializer(serializers.ModelSerializer):
    """Detailed parking session serializer for officer app"""
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    driver_name = serializers.SerializerMethodField()
    driver_phone = serializers.CharField(source='vehicle.user.phone', read_only=True)
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    slot_number = serializers.CharField(source='parking_slot.slot_code', read_only=True)
    
    class Meta:
        model = ParkingSession
        fields = ['id', 'vehicle_plate', 'driver_name', 'driver_phone', 'zone_name',
                  'slot_number', 'start_time', 'planned_end_time', 'actual_end_time',
                  'status', 'estimated_cost', 'final_cost', 'created_at']
    
    def get_driver_name(self, obj):
        """Get driver's full name"""
        user = obj.vehicle.user
        return f"{user.first_name} {user.last_name}".strip() or user.email
