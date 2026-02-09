from rest_framework import serializers
from .models import Violation, ViolationEvidence

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
