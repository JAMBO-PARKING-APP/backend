from django.urls import path
from apps.analytics.api_views import AdminDashboardStatsAPIView, AdminTransactionListAPIView, AdminRefundListAPIView
from apps.parking.api_views import (
    AdminActiveSessionsAPIView, AdminParkingSessionListView, 
    AdminZoneSlotListView, AdminSlotUpdateView
)
from apps.accounts.api_views_v2 import AdminUserListAPIView
from apps.enforcement.api_views_v2 import AdminViolationListAPIView, AdminOfficerStatusListAPIView, AdminGlobalOfficerLogListAPIView

urlpatterns = [
    path('dashboard/stats/', AdminDashboardStatsAPIView.as_view(), name='admin-dashboard-stats'),
    path('parking/active-sessions/', AdminActiveSessionsAPIView.as_view(), name='admin-active-sessions'),
    path('parking/sessions/', AdminParkingSessionListView.as_view(), name='admin-parking-sessions'),
    path('parking/zones/<uuid:zone_id>/slots/', AdminZoneSlotListView.as_view(), name='admin-zone-slots'),
    path('parking/slots/<uuid:pk>/', AdminSlotUpdateView.as_view(), name='admin-slot-update'),
    path('users/', AdminUserListAPIView.as_view(), name='admin-user-list'),
    path('finance/transactions/', AdminTransactionListAPIView.as_view(), name='admin-transactions'),
    path('finance/refunds/', AdminRefundListAPIView.as_view(), name='admin-refunds'),
    path('enforcement/violations/', AdminViolationListAPIView.as_view(), name='admin-violations'),
    path('enforcement/officers/', AdminOfficerStatusListAPIView.as_view(), name='admin-officers'),
    path('enforcement/logs/', AdminGlobalOfficerLogListAPIView.as_view(), name='admin-enforcement-logs'),
]
