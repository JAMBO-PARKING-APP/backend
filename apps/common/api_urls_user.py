"""
API URL Configuration for User App
Provides all endpoints for Flutter mobile app
"""

from django.urls import path
from apps.accounts import api_views_v2 as accounts_views
from apps.parking import api_views_v2 as parking_views
from apps.enforcement import api_views_v2 as enforcement_views
from apps.payments import api_views_v2 as payments_views
from apps.notifications import api_views as notifications_views
from apps.common import api_views_help
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    # ========== AUTHENTICATION ==========
    path('auth/register/', accounts_views.RegisterAPIView.as_view(), name='register'),
    path('auth/verify-otp/', accounts_views.VerifyOTPAPIView.as_view(), name='verify-otp'),
    path('auth/login/', accounts_views.LoginAPIView.as_view(), name='login'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/resend-otp/', accounts_views.ResendOTPAPIView.as_view(), name='resend-otp'),
    path('auth/change-password/', accounts_views.ChangePasswordAPIView.as_view(), name='change-password'),
    path('auth/delete-account/', accounts_views.DeleteAccountAPIView.as_view(), name='delete-account'),
    
    # ========== USER PROFILE ==========
    path('profile/', accounts_views.ProfileAPIView.as_view(), name='profile'),
    
    # ========== VEHICLES ==========
    path('vehicles/', accounts_views.VehicleListCreateAPIView.as_view(), name='vehicle-list-create'),
    path('vehicles/<uuid:pk>/', accounts_views.VehicleDetailAPIView.as_view(), name='vehicle-detail'),
    
    # ========== PAYMENT METHODS ==========
    path('payment-methods/', payments_views.PaymentMethodsListAPIView.as_view(), name='payment-methods'),
    path('payment-methods/<uuid:pk>/set-default/', payments_views.SetDefaultPaymentMethodAPIView.as_view(), 
         name='set-default-payment-method'),
    
    # ========== ZONES / PARKING LOCATIONS ==========
    path('zones/', parking_views.ZoneListAPIView.as_view(), name='zone-list'),
    path('zones/<uuid:pk>/', parking_views.ZoneDetailAPIView.as_view(), name='zone-detail'),
    path('zones/<int:zone_id>/availability/', parking_views.ZoneAvailabilityAPIView.as_view(), name='zone-availability'),
    
    # ========== PARKING SESSIONS ==========
    path('parking/start/', parking_views.StartParkingAPIView.as_view(), name='start-parking'),
    path('parking/end/', parking_views.EndParkingAPIView.as_view(), name='end-parking'),
    path('parking/extend/', parking_views.ExtendParkingAPIView.as_view(), name='extend-parking'),
    path('parking/cancel/', parking_views.CancelParkingSessionAPIView.as_view(), name='cancel-parking'),
    path('parking/sessions/', parking_views.UserParkingSessionsAPIView.as_view(), name='parking-sessions'),
    
    # ========== RESERVATIONS ==========
    path('reservations/create/', parking_views.CreateReservationAPIView.as_view(), name='create-reservation'),
    path('reservations/', parking_views.UserReservationsAPIView.as_view(), name='reservations'),
    path('reservations/<uuid:reservation_id>/cancel/', parking_views.CancelReservationAPIView.as_view(), 
         name='cancel-reservation'),
    
    # ========== VIOLATIONS ==========
    path('violations/', enforcement_views.UserViolationsListAPIView.as_view(), name='violations'),
    path('violations/<uuid:pk>/', enforcement_views.ViolationDetailAPIView.as_view(), name='violation-detail'),
    path('violations/summary/', enforcement_views.UnpaidViolationsCountAPIView.as_view(), name='violations-summary'),
    
    # ========== PAYMENTS / TRANSACTIONS ==========
    path('payments/create/', payments_views.CreatePaymentAPIView.as_view(), name='create-payment'),
    path('payments/pesapal/initiate/', payments_views.InitiatePesapalPaymentAPIView.as_view(), name='pesapal-initiate'),
    path('payments/pesapal/ipn/', payments_views.PesapalIPNAPIView.as_view(), name='pesapal-ipn'),
    path('transactions/', payments_views.TransactionListAPIView.as_view(), name='transactions'),
    path('transactions/<uuid:pk>/', payments_views.TransactionDetailAPIView.as_view(), name='transaction-detail'),
    path('invoices/', payments_views.InvoiceListAPIView.as_view(), name='invoices'),
    path('payments/summary/', payments_views.PaymentSummaryAPIView.as_view(), name='payment-summary'),
    
    # ========== WALLET ==========
    path('wallet/balance/', payments_views.WalletBalanceAPIView.as_view(), name='wallet-balance'),
    path('wallet/transactions/', payments_views.WalletTransactionsListAPIView.as_view(), name='wallet-transactions'),
    
    # ========== NOTIFICATIONS ==========
    path('notifications/', notifications_views.NotificationListAPIView.as_view(), name='notification-list'),
    path('notifications/<uuid:pk>/', notifications_views.NotificationDetailAPIView.as_view(), name='notification-detail'),
    path('notifications/summary/', notifications_views.NotificationSummaryAPIView.as_view(), name='notification-summary'),
    path('notifications/mark-all-as-read/', notifications_views.MarkAllNotificationsAsReadAPIView.as_view(), name='mark-all-as-read'),
    
    # ========== USER PREFERENCES ==========
    path('preferences/', notifications_views.UserPreferencesAPIView.as_view(), name='user-preferences'),
    
    # ========== HELP CENTER ==========
    path('help/', api_views_help.HelpCenterListAPIView.as_view(), name='help-list'),
    path('help/<int:item_id>/', api_views_help.HelpCenterDetailAPIView.as_view(), name='help-detail'),
]