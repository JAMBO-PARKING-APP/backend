from django.urls import path
from . import api_views

urlpatterns = [
    # Officer Dashboard
    path('zones/', api_views.OfficerZoneListView.as_view(), name='officer-zones'),
    path('zones/<uuid:pk>/', api_views.ZoneDetailView.as_view(), name='zone-detail'),
    path('zones/<uuid:zone_id>/slots/', api_views.ZoneSlotsView.as_view(), name='zone-slots'),
    path('zones/<uuid:zone_id>/live-status/', api_views.zone_live_status, name='zone-live-status'),
    
    # Vehicle Search
    path('search/vehicle/', api_views.search_vehicle, name='search-vehicle'),
    
    # Violations
    path('violations/create/', api_views.CreateViolationView.as_view(), name='create-violation'),
    
    # Officer Stats
    path('stats/', api_views.officer_stats, name='officer-stats'),
]