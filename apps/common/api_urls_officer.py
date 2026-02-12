from django.urls import path
from apps.parking.api_views_officer import (
    verify_qr_code,
    officer_zones,
    officer_zone_sessions
)

urlpatterns = [
    # QR Code Verification
    path('verify-qr/', verify_qr_code, name='officer-verify-qr'),
    
    # Zone Management
    path('zones/', officer_zones, name='officer-zones'),
    path('zones/<uuid:zone_id>/sessions/', officer_zone_sessions, name='officer-zone-sessions'),
]
