from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/admin/realtime-monitor/$', consumers.RealtimeMonitorConsumer.as_asgi()),
]</content>
<parameter name="filePath">c:\Users\callc\Downloads\backend\apps\common\routing.py