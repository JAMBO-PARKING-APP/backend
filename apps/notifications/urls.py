"""
URL Configuration for Notifications API
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.notifications import api_views
from apps.notifications import chat_views

# Create router for chat viewset
router = DefaultRouter()
router.register(r'chat/conversations', chat_views.ChatConversationViewSet, basename='chat-conversation')

urlpatterns = [
    # Chat endpoints
    path('', include(router.urls)),
    
    # Notification endpoints
    path('notifications/', api_views.NotificationListAPIView.as_view(), name='notification-list'),
    path('notifications/<int:pk>/', api_views.NotificationDetailAPIView.as_view(), name='notification-detail'),
    path('notifications/summary/', api_views.NotificationSummaryAPIView.as_view(), name='notification-summary'),
    path('notifications/mark-all-as-read/', api_views.MarkAllNotificationsAsReadAPIView.as_view(), name='mark-all-as-read'),
    
    # User preferences endpoints
    path('preferences/', api_views.UserPreferencesAPIView.as_view(), name='user-preferences'),
    # OTP endpoints
    path('otp/send/', api_views.SendOTPAPIView.as_view(), name='otp-send'),
    path('otp/verify/', api_views.VerifyOTPAPIView.as_view(), name='otp-verify'),
    
    # Admin endpoints
    path('create/<int:user_id>/', api_views.CreateNotificationAPIView.as_view(), name='create-notification'),
    path('bulk-create/', api_views.BulkCreateNotificationsAPIView.as_view(), name='bulk-create-notifications'),
]
