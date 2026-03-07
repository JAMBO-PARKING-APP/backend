from django.urls import path
from apps.analytics.api_views import AdminDashboardStatsAPIView, AdminTransactionListAPIView, AdminRefundListAPIView
from apps.parking.api_views import (
    AdminActiveSessionsAPIView, AdminParkingSessionListView, 
    AdminZoneSlotListView, AdminSlotUpdateView,
    AdminZoneListCreateAPIView, AdminZoneDetailAPIView
)
from apps.accounts.api_views_v2 import AdminUserListAPIView
from apps.enforcement.api_views_v2 import (
    AdminViolationListAPIView, AdminOfficerStatusListAPIView,
    AdminGlobalOfficerLogListAPIView, AdminOfficerReassignAPIView
)

from apps.common.api_views import AdminCountryListAPIView, AdminCountryDetailAPIView, AdminSystemSettingsAPIView, SystemHealthAPIView
from apps.notifications.api_views import (
    AdminNotificationEventAPIView, BulkCreateNotificationsAPIView,
    AdminChatConversationListAPIView, AdminChatMessageListAPIView,
    SendCustomNotificationAPIView
)

urlpatterns = [
    path('dashboard/stats/', AdminDashboardStatsAPIView.as_view(), name='admin-dashboard-stats'),
    path('enforcement/officers/<uuid:pk>/reassign/', AdminOfficerReassignAPIView.as_view(), name='admin-officer-reassign'),
    path('system/health/', SystemHealthAPIView.as_view(), name='admin-system-health'),
    path('system/settings/', AdminSystemSettingsAPIView.as_view(), name='admin-system-settings'),
    path('support/conversations/', AdminChatConversationListAPIView.as_view(), name='admin-chat-list'),
    path('support/conversations/<uuid:conversation_id>/messages/', AdminChatMessageListAPIView.as_view(), name='admin-chat-messages'),
    path('notifications/history/', AdminNotificationEventAPIView.as_view(), name='admin-notification-history'),
    path('notifications/broadcast/', BulkCreateNotificationsAPIView.as_view(), name='admin-notification-broadcast'),
    path('notifications/custom/', SendCustomNotificationAPIView.as_view(), name='admin-notification-custom'),
    path('common/countries/', AdminCountryListAPIView.as_view(), name='admin-country-list'),
    path('common/countries/<uuid:pk>/', AdminCountryDetailAPIView.as_view(), name='admin-country-detail'),
    path('parking/active-sessions/', AdminActiveSessionsAPIView.as_view(), name='admin-active-sessions'),
    path('parking/sessions/', AdminParkingSessionListView.as_view(), name='admin-parking-sessions'),
    path('parking/zones/', AdminZoneListCreateAPIView.as_view(), name='admin-zone-list'),
    path('parking/zones/<uuid:pk>/', AdminZoneDetailAPIView.as_view(), name='admin-zone-detail'),
    path('parking/zones/<uuid:zone_id>/slots/', AdminZoneSlotListView.as_view(), name='admin-zone-slots'),
    path('parking/slots/<uuid:pk>/', AdminSlotUpdateView.as_view(), name='admin-slot-update'),
    path('users/', AdminUserListAPIView.as_view(), name='admin-user-list'),
    path('finance/transactions/', AdminTransactionListAPIView.as_view(), name='admin-transactions'),
    path('finance/refunds/', AdminRefundListAPIView.as_view(), name='admin-refunds'),
    path('enforcement/violations/', AdminViolationListAPIView.as_view(), name='admin-violations'),
    path('enforcement/officers/', AdminOfficerStatusListAPIView.as_view(), name='admin-officers'),
    path('enforcement/logs/', AdminGlobalOfficerLogListAPIView.as_view(), name='admin-enforcement-logs'),
]
