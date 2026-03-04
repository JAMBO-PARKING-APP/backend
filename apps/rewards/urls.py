from django.urls import path
from .api_views import LoyaltyBalanceAPIView, LoyaltyHistoryAPIView

urlpatterns = [
    path('balance/', LoyaltyBalanceAPIView.as_view(), name='loyalty-balance'),
    path('history/', LoyaltyHistoryAPIView.as_view(), name='loyalty-history'),
]
