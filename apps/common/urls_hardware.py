from django.urls import path
from .api_views_hardware import HardwareGetAccessTokenView

urlpatterns = [
    path('', HardwareGetAccessTokenView.as_view(), name='hardware-token'),
]
