from rest_framework import serializers
from .models import Violation, OfficerLog
from apps.parking.models import Zone, ParkingSession, ParkingSlot
from apps.accounts.models import Vehicle, User
from apps.payments.models import Transaction

class ZoneSerializer(serializers.ModelSerializer):
    active_sessions_count = serializers.SerializerMethodField()
    total_capacity = serializers.SerializerMethodField()
    occupancy_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = Zone
        fields = ('id', 'name', 'description', 'hourly_rate', 'latitude', 'longitude', 
                 'radius_meters', 'is_active', 'active_sessions_count', 'total_capacity', 'occupancy_rate')
    
    def get_active_sessions_count(self, obj):
        return ParkingSession.objects.filter(zone=obj, status='active').count()
    
    def get_total_capacity(self, obj):
        return obj.slots.count() or 50
    
    def get_occupancy_rate(self, obj):
        total = self.get_total_capacity(obj)
        active = self.get_active_sessions_count(obj)
        return (active * 100) // total if total > 0 else 0

class ParkingSlotSerializer(serializers.ModelSerializer):
    current_session = serializers.SerializerMethodField()
    
    class Meta:
        model = ParkingSlot
        fields = ('id', 'slot_code', 'diagram_x', 'diagram_y', 'is_active', 'current_session')
    
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
            return {
                'id': str(session.id),
                'zone_name': session.zone.name,
                'start_time': session.start_time,
                'duration_minutes': session.duration_minutes,
                'amount_due': session.amount_due
            }
        return None
    
    def get_total_sessions(self, obj):
        return ParkingSession.objects.filter(vehicle=obj).count()
    
    def get_total_violations(self, obj):
        return Violation.objects.filter(vehicle=obj).count()
    
    def get_total_payments(self, obj):
        return Transaction.objects.filter(parking_session__vehicle=obj, status='completed').count()

class ViolationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Violation
        fields = ('id', 'vehicle', 'zone', 'violation_type', 'description', 
                 'fine_amount', 'evidence_photo', 'location_latitude', 'location_longitude', 
                 'is_paid', 'created_at')
        read_only_fields = ('id', 'created_at')