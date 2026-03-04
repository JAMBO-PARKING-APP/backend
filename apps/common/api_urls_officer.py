from django.urls import path
from apps.parking.api_views_officer import (
    verify_qr_code,
    officer_zones,
    officer_zone_sessions,
    overdue_users
)
from apps.accounts import api_views_v2 as accounts_views
from apps.enforcement import api_views_v2

urlpatterns = [
    path('verify-qr/', verify_qr_code, name='officer-verify-qr'),
    path('zones/', officer_zones, name='officer-zones'),
    path('zones/<uuid:zone_id>/sessions/', officer_zone_sessions, name='officer-zone-sessions'),
    path('zones/<uuid:zone_id>/overdue-users/', overdue_users, name='officer-overdue-users'),
    path('parking/start/', api_views_v2.StartSessionByOfficerAPIView.as_view(), name='officer-start-session'),
    path('location/', accounts_views.UserLocationAPIView.as_view(), name='officer-location'),
]
