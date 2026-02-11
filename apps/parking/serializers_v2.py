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
        return obj.available_slots_count
    
    def get_occupied_slots(self, obj):
        return obj.occupied_slots_count
    
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
        return obj.available_slots_count
    
    def get_occupied_slots(self, obj):
        return obj.occupied_slots_count
    
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
    duration_hours = serializers.DecimalField(max_digits=5, decimal_places=2, default=1, min_value=0.25, max_value=24)
    payment_method = serializers.ChoiceField(choices=['wallet', 'pesapal'], default='wallet')

class EndParkingSerializer(serializers.Serializer):
    session_id = serializers.UUIDField()

class ReservationSerializer(serializers.ModelSerializer):
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    start_time = serializers.DateTimeField(source='reserved_from', read_only=True)
    end_time = serializers.DateTimeField(source='reserved_until', read_only=True)
    status = serializers.SerializerMethodField()
    
    class Meta:
        model = Reservation
        fields = ['id', 'vehicle_plate', 'zone_name', 'start_time', 'end_time', 
                  'status', 'cost', 'created_at']
        read_only_fields = ['id', 'created_at', 'status', 'cost']

    def get_status(self, obj):
        if not obj.is_active:
             # Check if cancelled
             if obj.is_active is False: 
                 return 'cancelled'
        
        # Check for payment logic
        # Assuming Transaction model has a related_name='transactions' to Reservation
        from apps.common.constants import TransactionStatus
        has_payment = obj.transactions.filter(status=TransactionStatus.COMPLETED).exists()
        
        # Note: If no payment found, it's pending payment
        if not has_payment:
            return 'pending_payment'

        # Basic logic: if active -> 'active', if past -> 'completed'
        from django.utils import timezone
        now = timezone.now()
        if now > obj.reserved_until:
            return 'completed'
        elif not obj.is_active:
            return 'cancelled'
        return 'active'

class CreateReservationSerializer(serializers.Serializer):
    vehicle_id = serializers.UUIDField()
    zone_id = serializers.UUIDField()
    # Support both old and new field names
    start_time = serializers.DateTimeField(required=False)
    end_time = serializers.DateTimeField(required=False)
    reserved_from = serializers.DateTimeField(required=False)
    reserved_until = serializers.DateTimeField(required=False)

    def validate(self, data):
        """Ensure either start_time/end_time OR reserved_from/reserved_until are provided"""
        start = data.get('start_time') or data.get('reserved_from')
        end = data.get('end_time') or data.get('reserved_until')
        
        if not start:
             raise serializers.ValidationError("Start time (reserved_from) is required")
        if not end:
             raise serializers.ValidationError("End time (reserved_until) is required")
             
        return data
