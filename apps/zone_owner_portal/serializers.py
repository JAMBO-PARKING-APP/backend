from rest_framework import serializers
from .models import ZoneApplicationPublic, OwnerBankDetails


class ZoneApplicationPublicSerializer(serializers.ModelSerializer):
    class Meta:
        model = ZoneApplicationPublic
        fields = [
            'application_id', 'applicant_name', 'applicant_email', 'applicant_phone',
            'proposed_name', 'address', 'latitude', 'longitude',
            'total_slots', 'proposed_hourly_rate', 'operating_hours',
            'parking_surface', 'has_security', 'has_cctv', 'access_instructions',
            'documents', 'status', 'created_at',
        ]
        read_only_fields = ['application_id', 'status', 'created_at']


class ApplicationStatusSerializer(serializers.ModelSerializer):
    """Minimal serializer for public status checks"""
    class Meta:
        model = ZoneApplicationPublic
        fields = ['application_id', 'proposed_name', 'status', 'admin_notes', 'created_at']


class OwnerBankDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = OwnerBankDetails
        fields = ['id', 'bank_name', 'account_number', 'account_holder_name', 'updated_at']
        read_only_fields = ['id', 'updated_at']
