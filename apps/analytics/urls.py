from django.urls import path
from . import views

urlpatterns = [
    path('revenue/', views.RevenueReportView.as_view(), name='revenue-report'),
    path('health/', views.SystemHealthView.as_view(), name='system-health'),
]
