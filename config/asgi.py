import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from channels.security.websocket import AllowedHostsOriginValidator
from django.urls import path

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.production')

django_asgi_app = get_asgi_application()
from apps.notifications.routing import websocket_urlpatterns as notification_websocket_urlpatterns
from apps.common.routing import websocket_urlpatterns as common_websocket_urlpatterns
from apps.common.channels_middleware import JWTAuthMiddlewareStack

all_websocket_urlpatterns = notification_websocket_urlpatterns + common_websocket_urlpatterns

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AllowedHostsOriginValidator(
        AuthMiddlewareStack(
            URLRouter(
                all_websocket_urlpatterns
            )
        )
    ),
})
