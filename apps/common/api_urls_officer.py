from django.urls import path
from apps.parking.api_views_officer import (
    verify_qr_code,
    officer_zones,
    officer_zone_sessions,
    overdue_users
)
from apps.accounts import api_views_v2 as accounts_views
from apps.enforcement import api_views_v2
from apps.payments import api_views_v2 as payments_views

urlpatterns = [
    path('verify-qr/', verify_qr_code, name='officer-verify-qr'),
    path('zones/', officer_zones, name='officer-zones'),
    path('zones/<uuid:zone_id>/sessions/', officer_zone_sessions, name='officer-zone-sessions'),
    path('zones/<uuid:zone_id>/overdue-users/', overdue_users, name='officer-overdue-users'),
    path('parking/start/', api_views_v2.StartSessionByOfficerAPIView.as_view(), name='officer-start-session'),
    path('parking/guest/', api_views_v2.CreateGuestParkingSessionAPIView.as_view(), name='officer-create-guest-session'),
    path('sessions/non-app-user/', api_views_v2.CreateGuestParkingSessionAPIView.as_view(), name='officer-create-non-app-session'),
    path('sessions/<uuid:session_id>/confirm-payment/', api_views_v2.ConfirmGuestSessionPaymentAPIView.as_view(), name='officer-confirm-payment'),
    path('search/plate/', api_views_v2.OfficerVehicleStatusAPIView.as_view(), name='officer-search-plate'),
    path('location/', accounts_views.UserLocationAPIView.as_view(), name='officer-location'),
    path('payments/pesapal/initiate/', payments_views.OfficerInitiatePesapalPaymentAPIView.as_view(), name='officer-pesapal-initiate'),
    path('payments/pesapal/callback/', payments_views.OfficerPesapalCallbackAPIView.as_view(), name='officer-pesapal-callback'),
]
