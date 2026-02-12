from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from django.conf.urls.i18n import i18n_patterns

urlpatterns = [
    # User Mobile App API
    path('api/user/', include('apps.common.api_urls_user')),  # User app - Flutter
    
    # Legacy API endpoints
    path('api/auth/', include('apps.accounts.urls')),
    path('api/parking/', include('apps.parking.urls')),
    path('api/payments/', include('apps.payments.urls')),
    path('api/enforcement/', include('apps.enforcement.urls')),
    path('api/officer/', include('apps.enforcement.api_urls')),  # Officer mobile API (violations)
    path('api/officer/', include('apps.common.api_urls_officer')),  # Officer mobile API (zones, QR)
    
    # Shared endpoints for both apps
    path('api/notifications/', include('apps.notifications.urls')),  # Chat and notifications (for officer app)
    
    path('i18n/', include('django.conf.urls.i18n')),
]

urlpatterns += i18n_patterns(
    path('admin/', admin.site.urls),
    path('', include('apps.common.urls')),  # Web interface
)

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)