import os
from django.utils import timezone
from rest_framework import generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser, IsAuthenticated
from .models import Country, SystemConfiguration
from .serializers import CountrySerializer, SystemConfigurationSerializer
from .services.country_terms_service import CountryTermsService

class AdminCountryListAPIView(generics.ListCreateAPIView):
    """List and create countries for admin management"""
    queryset = Country.objects.all().order_by('name')
    serializer_class = CountrySerializer
    permission_classes = [IsAdminUser]
    pagination_class = None

class AdminCountryDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a country for admin management"""
    queryset = Country.objects.all()
    serializer_class = CountrySerializer
    permission_classes = [IsAdminUser]


class AdminSystemSettingsAPIView(generics.RetrieveUpdateAPIView):
    """Get and update global system configuration"""
    queryset = SystemConfiguration.objects.all()
    serializer_class = SystemConfigurationSerializer
    permission_classes = [IsAdminUser]

    def get_object(self):
        return SystemConfiguration.get_config()


def _get_system_usage():
    """Return current CPU and memory metrics for the server."""
    try:
        import psutil
        virtual = psutil.virtual_memory()
        return {
            'cpu_percent': psutil.cpu_percent(interval=0.2),
            'memory_total_mb': round(virtual.total / 1024**2, 2),
            'memory_used_mb': round(virtual.used / 1024**2, 2),
            'memory_percent': virtual.percent,
        }
    except Exception:
        pass

    try:
        if os.path.exists('/proc/meminfo'):
            meminfo = {}
            with open('/proc/meminfo', 'r') as fh:
                for line in fh:
                    key, value = line.split(':', 1)
                    meminfo[key.strip()] = int(value.split()[0])
            total_kb = meminfo.get('MemTotal')
            avail_kb = meminfo.get('MemAvailable', meminfo.get('MemFree', 0) + meminfo.get('Buffers', 0) + meminfo.get('Cached', 0))
            if total_kb:
                used_kb = total_kb - avail_kb
                return {
                    'cpu_percent': None,
                    'memory_total_mb': round(total_kb / 1024, 2),
                    'memory_used_mb': round(used_kb / 1024, 2),
                    'memory_percent': round((used_kb / total_kb) * 100, 2),
                }
    except Exception:
        pass

    return {
        'cpu_percent': None,
        'memory_total_mb': None,
        'memory_used_mb': None,
        'memory_percent': None,
    }


class SystemHealthAPIView(APIView):
    """Infrastructure health check for admin view"""
    permission_classes = [IsAdminUser]

    def get(self, request):
        import shutil
        import os
        from django.db import connection
        from django.core.cache import cache

        db_ok = True
        try:
            connection.ensure_connection()
        except Exception:
            db_ok = False

        cache_ok = True
        try:
            cache.set('health_check', 1, 5)
            if not cache.get('health_check'):
                cache_ok = False
        except Exception:
            cache_ok = False

        total, used, free = shutil.disk_usage("/")
        disk_usage_pct = (used / total) * 100
        system_usage = _get_system_usage()

        return Response({
            'services': [
                {'name': 'Core API Layer', 'status': 'Operational', 'color': 'success'},
                {'name': 'PostgreSQL DB', 'status': 'Connected' if db_ok else 'Disconnected', 'color': 'success' if db_ok else 'error'},
                {'name': 'Redis Cache', 'status': 'Active' if cache_ok else 'Degraded', 'color': 'success' if cache_ok else 'warning'},
                {'name': 'Static Assets', 'status': 'Healthy', 'color': 'success'}
            ],
            'resources': {
                'cpu_percent': system_usage.get('cpu_percent'),
                'memory_total_mb': system_usage.get('memory_total_mb'),
                'memory_used_mb': system_usage.get('memory_used_mb'),
                'memory_percent': system_usage.get('memory_percent'),
                'disk_percent': round(disk_usage_pct, 1),
            },
            'timestamp': timezone.now()
        })


class SystemMonitorAPIView(APIView):
    """Detailed system and Celery monitoring endpoint for admin use."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        from django.conf import settings
        from django.core.cache import cache
        from config.celery import app as celery_app
        from django.db import connection
        from django_redis import get_redis_connection
        import shutil
        import os
        from .services.analytics_service import AnalyticsService

        monitor_data = {
            'server_time': timezone.now().isoformat(),
            'health': {
                'database': False,
                'redis': False,
                'disk_usage_percent': None,
            },
            'celery': {
                'heartbeat': None,
                'workers': {},
                'stats': {},
                'active': {},
                'scheduled': {},
                'reserved': {},
            },
            'schedule': [],
            'country_breakdown': {},
            'event_feed': [],
        }

        # ... existing logic ...
        try:
            connection.ensure_connection()
            monitor_data['health']['database'] = True
        except Exception as exc:
            monitor_data['health']['database'] = False

        try:
            cache.set('health_check_monitor', 'ok', timeout=10)
            monitor_data['health']['redis'] = cache.get('health_check_monitor') == 'ok'
        except Exception as exc:
            monitor_data['health']['redis'] = False

        try:
            total, used, free = shutil.disk_usage(settings.BASE_DIR)
            monitor_data['health']['disk_usage_percent'] = round((used / total) * 100, 2)
        except Exception as exc:
            pass

        monitor_data['resources'] = _get_system_usage()

        # Business and Country stats
        monitor_data['country_breakdown'] = AnalyticsService.get_realtime_metrics()
        monitor_data['event_feed'] = AnalyticsService.get_unified_event_feed()
        
        # Enrich country breakdown with Redis info
        redis_client = get_redis_connection('default')
        for code, stats in monitor_data['country_breakdown'].items():
            stats['system'] = {
                'requests_total': int(redis_client.get(f"monitor:requests:country:{code}:total") or 0),
                'status_2xx': int(redis_client.get(f"monitor:requests:country:{code}:2xx") or 0),
                'status_4xx': int(redis_client.get(f"monitor:requests:country:{code}:4xx") or 0),
                'status_5xx': int(redis_client.get(f"monitor:requests:country:{code}:5xx") or 0),
                'latency_last': float(redis_client.get(f"monitor:latency:country:{code}:last") or 0),
            }

        heartbeat = cache.get('celery_heartbeat')
        monitor_data['celery']['heartbeat'] = heartbeat
        if heartbeat:
            monitor_data['celery']['heartbeat_age_seconds'] = (timezone.now() - timezone.datetime.fromisoformat(heartbeat['timestamp'])).total_seconds()

        try:
            inspector = celery_app.control.inspect()
            monitor_data['celery']['active'] = inspector.active() or {}
            monitor_data['celery']['scheduled'] = inspector.scheduled() or {}
            monitor_data['celery']['reserved'] = inspector.reserved() or {}
            monitor_data['celery']['workers'] = inspector.registered() or {}
            monitor_data['celery']['stats'] = inspector.stats() or {}
        except Exception as exc:
            monitor_data['celery']['inspect_error'] = str(exc)

        for name, schedule in settings.CELERY_BEAT_SCHEDULE.items():
            monitor_data['schedule'].append({
                'name': name,
                'task': schedule.get('task'),
                'schedule': str(schedule.get('schedule'))
            })

        return Response(monitor_data)


from rest_framework.permissions import AllowAny
import requests as http_requests

class PublicSystemConfigAPIView(generics.RetrieveAPIView):
    """Public version of system configuration for mobile app startup (version check, etc)"""
    queryset = SystemConfiguration.objects.all()
    serializer_class = SystemConfigurationSerializer
    permission_classes = [AllowAny]

    def get_object(self):
        return SystemConfiguration.get_config()


class PublicCountryListAPIView(generics.ListAPIView):
    """Public endpoint: returns all active countries for the mobile app."""
    serializer_class = CountrySerializer
    permission_classes = [AllowAny]
    pagination_class = None

    def get_queryset(self):
        return Country.objects.filter(is_active=True).order_by('name')


class CountryDetectAPIView(APIView):
    """
    Public endpoint: detects the country of the requesting device using IP geolocation.
    Returns country details and whether it is active in the SPACE system.
    The Flutter app calls this on startup to auto-detect and gate access.
    """
    permission_classes = [AllowAny]

    def _get_client_ip(self, request):
        """Extract real IP, respecting proxy headers."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '')

    def get(self, request):
        client_ip = self._get_client_ip(request)
        iso_code_override = request.query_params.get('iso_code')
        if iso_code_override:
            try:
                country = Country.objects.get(iso_code=iso_code_override.upper())
                return Response({
                    'detected': True,
                    'iso_code': country.iso_code,
                    'name': country.name,
                    'flag_emoji': country.flag_emoji,
                    'currency': country.currency,
                    'currency_symbol': country.currency_symbol,
                    'phone_code': country.phone_code,
                    'timezone': country.timezone,
                    'is_active': country.is_active,
                })
            except Country.DoesNotExist:
                return Response({'detected': False, 'is_active': False, 'iso_code': iso_code_override.upper()})
        detected_iso = None
        detected_name = None
        try:
            geo_resp = http_requests.get(
                f'http://ip-api.com/json/{client_ip}?fields=status,countryCode,country',
                timeout=3,
            )
            if geo_resp.status_code == 200:
                geo_data = geo_resp.json()
                if geo_data.get('status') == 'success':
                    detected_iso = geo_data.get('countryCode', '').upper()
                    detected_name = geo_data.get('country', '')
        except Exception:
            pass 

        if not detected_iso:
            return Response({
                'detected': False,
                'is_active': False,
                'message': 'Could not determine your location. Please check your connection.',
            })

        try:
            country = Country.objects.get(iso_code=detected_iso)
            return Response({
                'detected': True,
                'iso_code': country.iso_code,
                'name': country.name,
                'flag_emoji': country.flag_emoji,
                'currency': country.currency,
                'currency_symbol': country.currency_symbol,
                'phone_code': country.phone_code,
                'timezone': country.timezone,
                'is_active': country.is_active,
            })
        except Country.DoesNotExist:
            return Response({
                'detected': True,
                'is_active': False,
                'iso_code': detected_iso,
                'name': detected_name or detected_iso,
                'flag_emoji': '',
            })


class CountryTermsAPIView(APIView):
    """Get country-specific terms and conditions"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user_country = getattr(request.user, 'country', None)
        language = request.GET.get('language', 'en')
        
        if not user_country:
            terms = CountryTermsService._get_default_terms()
        else:
            terms = CountryTermsService.get_country_specific_terms(user_country)

        privacy_policy = CountryTermsService.get_privacy_policy_for_country(user_country)
        
        return Response({
            'terms': terms,
            'privacy_policy': privacy_policy,
            'country': {
                'name': user_country.name if user_country else None,
                'iso_code': user_country.iso_code if user_country else None,
                'currency': user_country.currency if user_country else None,
                'currency_symbol': user_country.currency_symbol if user_country else None,
            },
            'language': language
        })


class CountryListAPIView(APIView):
    """Get list of all supported countries"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        countries = Country.objects.filter(is_active=True).order_by('name')
        country_data = []
        
        for country in countries:
            country_data.append({
                'id': str(country.id),
                'name': country.name,
                'iso_code': country.iso_code,
                'currency': country.currency,
                'currency_symbol': country.currency_symbol,
                'phone_code': country.phone_code,
                'flag_emoji': country.flag_emoji,
            })
        
        return Response({
            'countries': country_data,
            'count': len(country_data)
        })
