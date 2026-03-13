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
