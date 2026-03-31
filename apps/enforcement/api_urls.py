from django.urls import path
from . import api_views, api_views_v2

urlpatterns = [
    path('zones/<uuid:pk>/', api_views.ZoneDetailView.as_view(), name='zone-detail'),
    path('zones/<uuid:zone_id>/slots/', api_views.ZoneSlotsView.as_view(), name='zone-slots'),
    path('zones/<uuid:zone_id>/live-status/', api_views.zone_live_status, name='zone-live-status'),
    path('search/vehicle/', api_views.search_vehicle, name='search-vehicle'),
    path('search-vehicle/', api_views_v2.SearchVehicleByPlateAPIView.as_view(), name='officer-search-vehicle'),
    path('vehicle-status/', api_views_v2.OfficerVehicleStatusAPIView.as_view(), name='officer-vehicle-status'),
    path('start-session/', api_views_v2.StartSessionByOfficerAPIView.as_view(), name='officer-start-session'),
    path('stats/', api_views.officer_stats, name='officer-stats'),
    path('logs/create/', api_views.LogOfficerActionAPIView.as_view(), name='log-action'),
    path('logs/', api_views_v2.OfficerActivityLogsAPIView.as_view(), name='activity-logs'),
    path('status/', api_views_v2.OfficerStatusAPIView.as_view(), name='officer-status'),
    path('status/toggle/', api_views_v2.OfficerStatusToggleAPIView.as_view(), name='status-toggle'),
    path('scans/', api_views_v2.OfficerQRScansAPIView.as_view(), name='qr-scans'),
    path('sessions/non-app-user/', api_views_v2.CreateGuestParkingSessionAPIView.as_view(), name='create-guest-session'),
    path('sessions/<uuid:session_id>/confirm-payment/', api_views_v2.ConfirmGuestSessionPaymentAPIView.as_view(), name='confirm-guest-payment'),
    path('payments/pesapal/initiate/', api_views_v2.OfficerInitiatePesaPalPaymentAPIView.as_view(), name='officer-initiate-pesapal'),
]