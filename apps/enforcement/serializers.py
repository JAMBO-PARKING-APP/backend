from rest_framework import serializers
from .models import Violation, OfficerLog
from apps.parking.models import Zone, ParkingSession, ParkingSlot
from apps.accounts.models import Vehicle, User
from apps.payments.models import Transaction
from drf_spectacular.utils import extend_schema_field

class ZoneSerializer(serializers.ModelSerializer):
    active_sessions_count = serializers.SerializerMethodField()
    total_capacity = serializers.SerializerMethodField()
    occupancy_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = Zone
        fields = ('id', 'name', 'description', 'hourly_rate', 'latitude', 'longitude', 
                 'radius_meters', 'is_active', 'active_sessions_count', 'total_capacity', 'occupancy_rate')
    
    @extend_schema_field(serializers.IntegerField())
    def get_active_sessions_count(self, obj):
        return ParkingSession.objects.filter(zone=obj, status='active').count()
    
    @extend_schema_field(serializers.IntegerField())
    def get_total_capacity(self, obj):
        return obj.slots.count() or 50
    
    @extend_schema_field(serializers.IntegerField())
    def get_occupancy_rate(self, obj):
        total = self.get_total_capacity(obj)
        active = self.get_active_sessions_count(obj)
        return (active * 100) // total if total > 0 else 0

class ParkingSlotSerializer(serializers.ModelSerializer):
    current_session = serializers.SerializerMethodField()
    
    class Meta:
        model = ParkingSlot
        fields = ('id', 'slot_code', 'diagram_x', 'diagram_y', 'current_session')
    
    def get_current_session(self, obj):
        session = ParkingSession.objects.filter(parking_slot=obj, status='active').first()
        if session:
            return {
                'id': str(session.id),
                'vehicle_plate': session.vehicle.license_plate,
                'start_time': session.start_time,
                'duration_minutes': session.duration_minutes
            }
        return None

class VehicleDetailSerializer(serializers.ModelSerializer):
    owner = serializers.SerializerMethodField()
    current_session = serializers.SerializerMethodField()
    total_sessions = serializers.SerializerMethodField()
    total_violations = serializers.SerializerMethodField()
    total_payments = serializers.SerializerMethodField()
    
    class Meta:
        model = Vehicle
        fields = ('id', 'license_plate', 'make', 'model', 'color', 'owner', 
                 'current_session', 'total_sessions', 'total_violations', 'total_payments')
    
    def get_owner(self, obj):
        return {
            'name': obj.user.full_name,
            'phone': obj.user.phone,
            'email': obj.user.email
        }
    
    def get_current_session(self, obj):
        session = ParkingSession.objects.filter(vehicle=obj, status='active').first()
        if session:
            amount_due = float(session.final_cost) if session.final_cost is not None else float(session.estimated_cost)
            return {
                'id': str(session.id),
                'zone_name': session.zone.name,
                'start_time': session.start_time,
                'duration_minutes': session.duration_minutes,
                'amount_due': amount_due
            }
        return None
    
    def get_total_sessions(self, obj):
        return ParkingSession.objects.filter(vehicle=obj).count()
    
    def get_total_violations(self, obj):
        return Violation.objects.filter(vehicle=obj).count()
    
    def get_total_payments(self, obj):
        return Transaction.objects.filter(parking_session__vehicle=obj, status='completed').count()

class ViolationSerializer(serializers.ModelSerializer):
    vehicle_plate = serializers.CharField(write_only=True, required=False)
    zone = serializers.PrimaryKeyRelatedField(queryset=Zone.objects.all(), required=False, allow_null=True)
    
    class Meta:
        model = Violation
        fields = ('id', 'vehicle', 'vehicle_plate', 'officer', 'zone', 'parking_session', 'violation_type', 
                 'description', 'fine_amount', 'latitude', 'longitude', 'is_paid', 'created_at')
        read_only_fields = ('id', 'officer', 'created_at', 'vehicle')

    def to_internal_value(self, data):
        if hasattr(data, 'copy'):
            data = data.copy()
        
        from apps.common.utils import truncate_coord
        if 'latitude' in data:
            data['latitude'] = truncate_coord(data.get('latitude'))
        if 'longitude' in data:
            data['longitude'] = truncate_coord(data.get('longitude'))
            
        return super().to_internal_value(data)

    def validate(self, attrs):
        vehicle_plate = attrs.get('vehicle_plate')
        vehicle = attrs.get('vehicle')
        
        if not vehicle and vehicle_plate:
            try:
                attrs['vehicle'] = Vehicle.objects.get(license_plate__iexact=vehicle_plate)
            except Vehicle.DoesNotExist:
                raise serializers.ValidationError({"vehicle_plate": "Vehicle with this plate not found."})
        
        if not attrs.get('vehicle'):
            raise serializers.ValidationError({"vehicle": "Vehicle is required."})

        session = attrs.get('parking_session')
        zone = attrs.get('zone')

        if not zone and session:
            attrs['zone'] = session.zone
            zone = attrs['zone']
        if not zone:
            request = self.context.get('request')
            if request and request.user.is_authenticated:
                try:
                    from .models import OfficerStatus
                    status_obj = OfficerStatus.objects.get(officer=request.user)
                    if status_obj.current_zone:
                        attrs['zone'] = status_obj.current_zone
                except OfficerStatus.DoesNotExist:
                    pass

        if not attrs.get('zone'):
            raise serializers.ValidationError({"zone": "Zone is required and could not be inferred."})
            
        if 'vehicle_plate' in attrs:
            del attrs['vehicle_plate']
            
        return attrs

class OfficerActionLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = OfficerLog
        fields = ('id', 'officer', 'action', 'details', 'latitude', 'longitude', 'created_at')
        read_only_fields = ('id', 'officer', 'created_at')