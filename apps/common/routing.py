from django.urls import path
from . import consumers

websocket_urlpatterns = [
    path('ws/admin/realtime-monitor/', consumers.RealtimeMonitorConsumer.as_asgi()),
]