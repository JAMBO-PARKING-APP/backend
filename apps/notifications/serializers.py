"""
Serializers for Notifications App
"""
from rest_framework import serializers
from .models import NotificationEvent, UserPreferences, ChatConversation, ChatMessage


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


class ChatMessageSerializer(serializers.ModelSerializer):
    """Serialize individual chat messages"""
    sender_name = serializers.SerializerMethodField()
    sender_phone = serializers.CharField(source='sender.phone', read_only=True)
    
    class Meta:
        model = ChatMessage
        fields = [
            'id', 'conversation', 'sender', 'sender_name', 'sender_phone',
            'message_type', 'content', 'attachment', 'is_read', 'read_at',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'sender', 'is_read', 'read_at', 'created_at', 'updated_at']
    
    def get_sender_name(self, obj):
        return obj.sender.full_name


class ChatConversationSerializer(serializers.ModelSerializer):
    """Serialize chat conversations"""
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    user_phone = serializers.CharField(source='user.phone', read_only=True)
    agent_name = serializers.SerializerMethodField()
    agent_phone = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatConversation
        fields = [
            'id', 'user', 'user_name', 'user_phone',
            'subject', 'status', 'priority', 'category',
            'assigned_agent', 'agent_name', 'agent_phone',
            'unread_count', 'last_message',
            'created_at', 'resolved_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']
    
    def get_agent_name(self, obj):
        if obj.assigned_agent:
            return obj.assigned_agent.full_name
        return None
    
    def get_agent_phone(self, obj):
        if obj.assigned_agent:
            return obj.assigned_agent.phone
        return None
    
    def get_unread_count(self, obj):
        return obj.messages.filter(is_read=False).count()
    
    def get_last_message(self, obj):
        last_msg = obj.messages.last()
        if last_msg:
            return ChatMessageSerializer(last_msg).data
        return None


class CreateChatConversationSerializer(serializers.ModelSerializer):
    """Serializer for creating chat conversations"""
    
    class Meta:
        model = ChatConversation
        fields = ['subject', 'priority', 'category']


class SendChatMessageSerializer(serializers.ModelSerializer):
    """Serializer for sending chat messages"""
    
    class Meta:
        model = ChatMessage
        fields = ['message_type', 'content', 'attachment']


class FCMTokenSerializer(serializers.Serializer):
    """Serializer for registering/updating FCM device tokens"""
    token = serializers.CharField(max_length=255, required=True, help_text="FCM device token")
    
    def validate_token(self, value):
        if not value or len(value) < 10:
            raise serializers.ValidationError("Invalid FCM token")
        return value


class SendCustomNotificationSerializer(serializers.Serializer):
    """Serializer for sending custom notifications (admin only)"""
    user_id = serializers.UUIDField(required=False, help_text="Specific user ID (optional)")
    user_ids = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        help_text="List of user IDs (optional)"
    )
    role = serializers.ChoiceField(
        choices=['driver', 'officer', 'admin'],
        required=False,
        help_text="Send to all users with this role (optional)"
    )
    title = serializers.CharField(max_length=100, required=True)
    message = serializers.CharField(required=True)
    category = serializers.ChoiceField(
        choices=['parking', 'violations', 'payments', 'reservations', 'system', 'promo'],
        default='system'
    )
    data = serializers.JSONField(required=False, help_text="Additional custom data")
    
    def validate(self, attrs):
        # At least one target must be specified
        if not any([attrs.get('user_id'), attrs.get('user_ids'), attrs.get('role')]):
            raise serializers.ValidationError(
                "Must specify at least one of: user_id, user_ids, or role"
            )
        return attrs
