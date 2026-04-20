#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from apps.common.api_views import SystemMonitorAPIView
from rest_framework.test import APIRequestFactory

factory = APIRequestFactory()
request = factory.get('/api/admin/system/monitor/')
request.user = type('User', (), {'is_staff': True, 'is_active': True})()  # Mock admin user

view = SystemMonitorAPIView()
try:
    response = view.get(request)
    print("Response status:", response.status_code)
    print("Response data:", response.data)
except Exception as e:
    import traceback
    print("Exception:", e)
    traceback.print_exc()