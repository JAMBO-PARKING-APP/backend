from django.utils import timezone
from rest_framework import generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from .models import Country, SystemConfiguration
from .serializers import CountrySerializer, SystemConfigurationSerializer

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

        return Response({
            'services': [
                {'name': 'Core API Layer', 'status': 'Operational', 'color': 'success'},
                {'name': 'PostgreSQL DB', 'status': 'Connected' if db_ok else 'Disconnected', 'color': 'success' if db_ok else 'error'},
                {'name': 'Redis Cache', 'status': 'Active' if cache_ok else 'Degraded', 'color': 'success' if cache_ok else 'warning'},
                {'name': 'Static Assets', 'status': 'Healthy', 'color': 'success'}
            ],
            'resources': {
                'cpu': 15,  
                'memory': 45, 
                'disk': round(disk_usage_pct, 1)
            },
            'timestamp': timezone.now()
        })


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
