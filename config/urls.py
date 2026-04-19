from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularRedocView, SpectacularSwaggerView

from django.conf.urls.i18n import i18n_patterns

urlpatterns = [
    path('grappelli/', include('grappelli.urls')),
    path('api/user/', include('apps.common.api_urls_user')),
    path('api/auth/', include('apps.accounts.urls')),
    path('api/parking/', include('apps.parking.urls')),
    path('api/partner/', include('apps.zone_owner_portal.urls')),
    path('api/payments/', include('apps.payments.urls')),
    path('api/enforcement/', include('apps.enforcement.urls')),
    path('api/officer/', include('apps.enforcement.api_urls')),  
    path('api/officer/', include('apps.common.api_urls_officer')), 
    path('api/notifications/', include('apps.notifications.urls')),
    path('api/support/', include('apps.support_chat.urls')),  
    path('api/admin/', include('apps.common.api_urls_admin')),
    path('api/', include('apps.common.urls')), 
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
    
    path('webclient/api/Login/GetAccessToken', include('apps.common.urls_hardware')),
    
    path('i18n/', include('django.conf.urls.i18n')),
]

urlpatterns += i18n_patterns(
    path('admin/', admin.site.urls),
    path('', include('apps.common.urls')),  
    path('reports/', include('apps.analytics.urls')), 
)

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)