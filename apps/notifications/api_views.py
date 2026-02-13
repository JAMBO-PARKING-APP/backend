"""
API Views for Notifications
"""
from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.generics import ListAPIView, UpdateAPIView
from django.db.models import Q
from apps.notifications.models import NotificationEvent, UserPreferences
from apps.notifications.serializers import (
    NotificationSerializer, NotificationListSerializer, NotificationSummarySerializer,
    UserPreferencesSerializer, MarkNotificationAsReadSerializer
)


class NotificationListAPIView(ListAPIView):
    """List all notifications for the current user"""
    serializer_class = NotificationListSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        queryset = NotificationEvent.objects.filter(user=user)
        
        # Filter by category if provided
        category = self.request.query_params.get('category')
        if category and category != 'all':
            queryset = queryset.filter(category=category)
        
        # Filter by read status if provided
        read_status = self.request.query_params.get('read')
        if read_status == 'true':
            queryset = queryset.filter(is_read=True)
        elif read_status == 'false':
            queryset = queryset.filter(is_read=False)
        
        return queryset.order_by('-created_at')


class NotificationDetailAPIView(UpdateAPIView):
    """Get, update, or mark a specific notification as read"""
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return NotificationEvent.objects.filter(user=self.request.user)
    
    def put(self, request, pk=None):
        """Mark notification as read"""
        try:
            notification = self.get_queryset().get(pk=pk)
        except NotificationEvent.DoesNotExist:
            return Response(
                {'error': 'Notification not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        serializer = MarkNotificationAsReadSerializer(data=request.data)
        if serializer.is_valid():
            is_read = serializer.validated_data.get('is_read', True)
            if is_read:
                # User wants to mark as read, so we delete it
                notification.delete()
                return Response(
                    {'message': 'Notification deleted successfully'},
                    status=status.HTTP_204_NO_CONTENT
                )
            else:
                # If they want to mark as unread (unlikely in this context but supported by serializer)
                notification.is_read = False
                notification.save()
                return Response(
                    NotificationSerializer(notification).data,
                    status=status.HTTP_200_OK
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class NotificationSummaryAPIView(APIView):
    """Get notification summary (counts by category)"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        serializer = NotificationSummarySerializer({}, context={'request': request})
        return Response(serializer.data)


class MarkAllNotificationsAsReadAPIView(APIView):
    """Mark all notifications as read for current user"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        user = request.user
        count = NotificationEvent.objects.filter(
            user=user,
            is_read=False
        ).delete()
        
        return Response({
            'success': True,
            'message': f'{count[0] if isinstance(count, tuple) else count} notifications deleted'
        })


class UserPreferencesAPIView(APIView):
    """Get or update user preferences"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        """Get user preferences"""
        try:
            preferences = UserPreferences.objects.get(user=request.user)
        except UserPreferences.DoesNotExist:
            # Create default preferences if they don't exist
            preferences = UserPreferences.objects.create(user=request.user)
        
        serializer = UserPreferencesSerializer(preferences)
        return Response(serializer.data)
    
    def put(self, request):
        """Update user preferences"""
        try:
            preferences = UserPreferences.objects.get(user=request.user)
        except UserPreferences.DoesNotExist:
            preferences = UserPreferences.objects.create(user=request.user)
        
        serializer = UserPreferencesSerializer(
            preferences,
            data=request.data,
            partial=True
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CreateNotificationAPIView(APIView):
    """Create a notification (for testing/admin use)"""
    permission_classes = [permissions.IsAdminUser]
    
    def post(self, request, user_id=None):
        """Create a notification for a user"""
        from apps.accounts.models import User
        
        if not user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        data = request.data.copy()
        data['user'] = user.id
        
        serializer = NotificationSerializer(data=data)
        if serializer.is_valid():
            serializer.save(user=user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class BulkCreateNotificationsAPIView(APIView):
    """Create notifications for multiple users (for admin/backend use)"""
    permission_classes = [permissions.IsAdminUser]
    
    def post(self, request):
        """Create notifications for users matching certain criteria"""
        title = request.data.get('title')
        message = request.data.get('message')
        notification_type = request.data.get('type', 'system_alert')
        category = request.data.get('category', 'system')
        user_filter = request.data.get('user_filter')  # 'all', 'active', etc.
        
        if not title or not message:
            return Response(
                {'error': 'title and message are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        from apps.accounts.models import User
        
        if user_filter == 'all':
            users = User.objects.all()
        elif user_filter == 'active':
            users = User.objects.filter(is_active=True)
        else:
            users = User.objects.filter(is_active=True)
        
        created_count = 0
        for user in users:
            NotificationEvent.objects.create(
                user=user,
                title=title,
                message=message,
                type=notification_type,
                category=category,
            )
            created_count += 1
        
        return Response({
            'success': True,
            'created_count': created_count,
            'message': f'Created {created_count} notifications'
        })


class SendOTPAPIView(APIView):
    """Send an OTP SMS using Twilio Verify"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        phone = request.data.get('phone')
        channel = request.data.get('channel', 'sms')
        if not phone:
            return Response({'error': 'phone is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            from apps.notifications.twilio_service import send_verification
            verification = send_verification(to_phone=phone, channel=channel)
        except Exception as exc:
            return Response({'error': str(exc)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({'sid': getattr(verification, 'sid', None), 'status': getattr(verification, 'status', None)})


class VerifyOTPAPIView(APIView):
    """Check an OTP code sent via Twilio Verify"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        phone = request.data.get('phone')
        code = request.data.get('code')
        if not phone or not code:
            return Response({'error': 'phone and code are required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            from apps.notifications.twilio_service import check_verification
            result = check_verification(to_phone=phone, code=code)
        except Exception as exc:
            return Response({'error': str(exc)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({'status': getattr(result, 'status', None)})


class RegisterFCMTokenAPIView(APIView):
    """Register or update FCM device token for push notifications"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        from apps.notifications.serializers import FCMTokenSerializer
        from django.utils import timezone
        
        serializer = FCMTokenSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        token = serializer.validated_data['token']
        user = request.user
        
        # Update user's FCM token
        user.fcm_device_token = token
        user.fcm_token_updated_at = timezone.now()
        user.save(update_fields=['fcm_device_token', 'fcm_token_updated_at'])
        
        return Response({
            'success': True,
            'message': 'FCM token registered successfully'
        }, status=status.HTTP_200_OK)


class UnregisterFCMTokenAPIView(APIView):
    """Unregister FCM device token (on logout)"""
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        user = request.user
        
        # Clear user's FCM token
        user.fcm_device_token = None
        user.fcm_token_updated_at = None
        user.save(update_fields=['fcm_device_token', 'fcm_token_updated_at'])
        
        return Response({
            'success': True,
            'message': 'FCM token unregistered successfully'
        }, status=status.HTTP_200_OK)


class SendCustomNotificationAPIView(APIView):
    """Send custom push notifications (admin only)"""
    permission_classes = [permissions.IsAdminUser]
    
    def post(self, request):
        from apps.notifications.serializers import SendCustomNotificationSerializer
        from apps.notifications.notification_triggers import notify_custom
        from apps.notifications.firebase_service import send_notification_to_multiple_users
        from apps.accounts.models import User
        
        serializer = SendCustomNotificationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        data = serializer.validated_data
        title = data['title']
        message = data['message']
        category = data.get('category', 'system')
        custom_data = data.get('data', {})
        
        # Determine target users
        target_users = []
        
        if data.get('user_id'):
            # Single user
            try:
                user = User.objects.get(id=data['user_id'])
                target_users = [user]
            except User.DoesNotExist:
                return Response(
                    {'error': 'User not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
        
        elif data.get('user_ids'):
            # Multiple specific users
            target_users = User.objects.filter(id__in=data['user_ids'])
        
        elif data.get('role'):
            # All users with specific role
            target_users = User.objects.filter(role=data['role'], is_active=True)
        
        if not target_users:
            return Response(
                {'error': 'No target users found'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Send notifications
        sent_count = 0
        for user in target_users:
            notify_custom(user, title, message, category, custom_data)
            sent_count += 1
        
        return Response({
            'success': True,
            'sent_count': sent_count,
            'message': f'Sent {sent_count} notifications'
        }, status=status.HTTP_200_OK)
