from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import api_views

urlpatterns = [
    path('register/', api_views.RegisterView.as_view(), name='register'),
    path('verify-otp/', api_views.VerifyOTPView.as_view(), name='verify-otp'),
    path('login/', api_views.LoginView.as_view(), name='login'),
    path('refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('profile/', api_views.ProfileView.as_view(), name='profile'),
    path('vehicles/', api_views.VehicleListCreateView.as_view(), name='vehicles'),
]