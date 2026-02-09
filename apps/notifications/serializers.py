"""
Serializers for Notifications App
"""
from rest_framework import serializers
from .models import NotificationEvent, UserPreferences


class NotificationSerializer(serializers.ModelSerializer):
    """Serialize notification events"""
    
    class Meta:
        model = NotificationEvent
        fields = [
            'id', 'title', 'message', 'type', 'category', 'is_read',
            'metadata', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class NotificationListSerializer(serializers.ModelSerializer):
    """Simplified notification serializer for list views"""
    
    class Meta:
        model = NotificationEvent
        fields = ['id', 'title', 'message', 'type', 'category', 'is_read', 'created_at']
        read_only_fields = ['id', 'created_at']


class NotificationSummarySerializer(serializers.Serializer):
    """Summary of notification counts"""
    unread_count = serializers.SerializerMethodField()
    total_count = serializers.SerializerMethodField()
    parking_count = serializers.SerializerMethodField()
    violation_count = serializers.SerializerMethodField()
    payment_count = serializers.SerializerMethodField()
    
    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return request.user.notifications.filter(is_read=False).count()
        return 0
    
    def get_total_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return request.user.notifications.count()
        return 0
    
    def get_parking_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return request.user.notifications.filter(category='parking').count()
        return 0
    
    def get_violation_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return request.user.notifications.filter(category='violations').count()
        return 0
    
    def get_payment_count(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return request.user.notifications.filter(category='payments').count()
        return 0


class UserPreferencesSerializer(serializers.ModelSerializer):
    """Serialize user preferences"""
    
    class Meta:
        model = UserPreferences
        fields = [
            'id', 'language', 'currency',
            'enable_parking_notifications', 'enable_violation_notifications',
            'enable_payment_notifications', 'enable_promotional_notifications',
            'enable_push_notifications', 'enable_sms_notifications',
            'enable_email_notifications',
            'theme_mode', 'font_size',
            'biometric_enabled', 'two_factor_enabled',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class CreateNotificationSerializer(serializers.ModelSerializer):
    """Serializer for creating notifications (admin/backend use)"""
    
    class Meta:
        model = NotificationEvent
        fields = ['title', 'message', 'type', 'category', 'metadata']


class MarkNotificationAsReadSerializer(serializers.Serializer):
    """Serializer for marking notifications as read"""
    is_read = serializers.BooleanField(default=True)
