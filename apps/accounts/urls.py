from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import api_views_v2 as api_views

urlpatterns = [
    path('register/', api_views.RegisterAPIView.as_view(), name='register'),
    path('verify-otp/', api_views.VerifyOTPAPIView.as_view(), name='verify-otp'),
    path('login/', api_views.LoginAPIView.as_view(), name='login'),
    path('resend-otp/', api_views.ResendOTPAPIView.as_view(), name='resend-otp'),
    path('refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('profile/', api_views.ProfileAPIView.as_view(), name='profile'),
    path('vehicles/', api_views.VehicleListCreateAPIView.as_view(), name='vehicles'),
    path('delete-account/', api_views.DeleteAccountAPIView.as_view(), name='delete-account'),
    path('location/', api_views.UserLocationAPIView.as_view(), name='user-location'),
]