from django.urls import path
from . import api_views, api_views_v2

urlpatterns = [
    path('zones/<uuid:pk>/', api_views.ZoneDetailView.as_view(), name='zone-detail'),
    path('zones/<uuid:zone_id>/slots/', api_views.ZoneSlotsView.as_view(), name='zone-slots'),
    path('zones/<uuid:zone_id>/live-status/', api_views.zone_live_status, name='zone-live-status'),
    path('search/vehicle/', api_views.search_vehicle, name='search-vehicle'),
    path('search/plate/', api_views_v2.SearchVehicleByPlateAPIView.as_view(), name='search-plate'),
    path('violations/create/', api_views.CreateViolationView.as_view(), name='create-violation'),
    path('stats/', api_views.officer_stats, name='officer-stats'),
    path('logs/create/', api_views.LogOfficerActionAPIView.as_view(), name='log-action'),
    path('logs/', api_views_v2.OfficerActivityLogsAPIView.as_view(), name='activity-logs'),
    path('status/', api_views_v2.OfficerStatusAPIView.as_view(), name='officer-status'),
    path('status/toggle/', api_views_v2.OfficerStatusToggleAPIView.as_view(), name='status-toggle'),
    path('qr-scan/', api_views_v2.ScanQRCodeAPIView.as_view(), name='qr-scan'),
    path('scans/', api_views_v2.OfficerQRScansAPIView.as_view(), name='qr-scans'),
]