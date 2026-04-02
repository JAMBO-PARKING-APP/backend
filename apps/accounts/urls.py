from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import api_views_v2 as api_views
from . import location_and_features_views as feature_views
from . import notification_views as notif_views

urlpatterns = [
    path('register/', api_views.RegisterAPIView.as_view(), name='register'),
    path('verify-otp/', api_views.VerifyOTPAPIView.as_view(), name='verify-otp'),
    path('login/', api_views.LoginAPIView.as_view(), name='login'),
    path('resend-otp/', api_views.ResendOTPAPIView.as_view(), name='resend-otp'),
    path('refresh/', api_views.CustomTokenRefreshAPIView.as_view(), name='token-refresh'),
    path('profile/', api_views.ProfileAPIView.as_view(), name='profile'),
    path('profile/picture/', notif_views.UserProfilePictureAPIView.as_view(), name='profile-picture'),
    path('vehicles/', api_views.VehicleListCreateAPIView.as_view(), name='vehicles'),
    path('delete-account/', api_views.DeleteAccountAPIView.as_view(), name='delete-account'),
    path('location/', feature_views.UserLocationAPIView.as_view(), name='user-location'),
    path('country/', feature_views.CountryDetectionAPIView.as_view(), name='country-detection'),
    path('reservations/', feature_views.UserReservationsAPIView.as_view(), name='user-reservations'),
    path('reservations/<uuid:pk>/', feature_views.ReservationDetailAPIView.as_view(), name='reservation-detail'),
    path('notifications/', notif_views.UserNotificationsAPIView.as_view(), name='user-notifications'),
    path('notifications/<uuid:notification_id>/read/', notif_views.NotificationActionAPIView.as_view(), name='notification-read'),
    path('notifications/<uuid:notification_id>/', notif_views.NotificationActionAPIView.as_view(), name='notification-delete'),
    path('host/dashboard/', feature_views.HostParkingDashboardAPIView.as_view(), name='host-dashboard'),
    path('host/zones/<uuid:zone_id>/settings/', feature_views.HostZoneSettingsAPIView.as_view(), name='host-zone-settings'),
]