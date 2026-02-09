from django.urls import path
from . import api_views

urlpatterns = [
    path('zones/', api_views.ZoneListView.as_view(), name='zones'),
    path('zones/<uuid:zone_id>/availability/', api_views.ZoneAvailabilityView.as_view(), name='zone-availability'),
    path('sessions/start/', api_views.StartParkingView.as_view(), name='start-parking'),
    path('sessions/extend/', api_views.ExtendParkingView.as_view(), name='extend-parking'),
    path('sessions/end/', api_views.EndParkingView.as_view(), name='end-parking'),
    path('sessions/active/', api_views.ActiveSessionView.as_view(), name='active-session'),
    path('reservations/', api_views.ReservationListCreateView.as_view(), name='reservations'),
]