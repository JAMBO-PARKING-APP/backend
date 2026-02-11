from rest_framework import serializers
from .models import Violation, ViolationEvidence, OfficerStatus, QRCodeScan, OfficerLog

class ViolationEvidenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = ViolationEvidence
        fields = ['id', 'image', 'description']

class ViolationListSerializer(serializers.ModelSerializer):
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    
    class Meta:
        model = Violation
        fields = ['id', 'vehicle_plate', 'zone_name', 'violation_type', 'fine_amount',
                  'is_paid', 'paid_at', 'created_at']

class ViolationDetailSerializer(serializers.ModelSerializer):
    vehicle_plate = serializers.CharField(source='vehicle.license_plate', read_only=True)
    zone_name = serializers.CharField(source='zone.name', read_only=True)
    evidence = ViolationEvidenceSerializer(many=True, read_only=True)
    
    class Meta:
        model = Violation
        fields = ['id', 'vehicle_plate', 'zone_name', 'violation_type', 'description',
                  'fine_amount', 'latitude', 'longitude', 'is_paid', 'paid_at',
                  'evidence', 'created_at']

class OfficerStatusSerializer(serializers.ModelSerializer):
    officer_name = serializers.CharField(source='officer.full_name', read_only=True)
    officer_phone = serializers.CharField(source='officer.phone', read_only=True)
    zone_name = serializers.CharField(source='current_zone.name', read_only=True, allow_null=True)
    
    class Meta:
        model = OfficerStatus
        fields = ['id', 'officer_name', 'officer_phone', 'is_online', 'went_online_at', 
                  'went_offline_at', 'zone_name', 'latitude', 'longitude', 'updated_at']

class QRCodeScanSerializer(serializers.ModelSerializer):
    officer_name = serializers.CharField(source='officer.full_name', read_only=True)
    vehicle_plate = serializers.CharField(source='parking_session.vehicle.license_plate', read_only=True)
    zone_name = serializers.CharField(source='parking_session.zone.name', read_only=True)
    
    class Meta:
        model = QRCodeScan
        fields = ['id', 'officer_name', 'vehicle_plate', 'zone_name', 'scan_status', 
                  'session_ended', 'latitude', 'longitude', 'created_at']

class OfficerLogSerializer(serializers.ModelSerializer):
    officer_name = serializers.CharField(source='officer.full_name', read_only=True)
    
    class Meta:
        model = OfficerLog
        fields = ['id', 'officer_name', 'action', 'details', 'latitude', 'longitude', 'created_at']
