from django.urls import path
from . import api_views

urlpatterns = [
    path('apply/', api_views.PublicApplyView.as_view(), name='partner-apply'),
    path('status/<uuid:application_id>/', api_views.ApplicationStatusView.as_view(), name='partner-status'),
    path('login/', api_views.PartnerLoginView.as_view(), name='partner-login'),
    path('bank-details/', api_views.BankDetailsView.as_view(), name='partner-bank-details'),
    path('dashboard/', api_views.OwnerDashboardView.as_view(), name='partner-dashboard'),
    path('change-password/', api_views.PartnerChangePasswordView.as_view(), name='partner-change-password'),
]
