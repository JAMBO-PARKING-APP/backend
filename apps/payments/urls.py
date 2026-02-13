from django.urls import path
from . import api_views
from . import api_views_v2
from . import pesapal_views

urlpatterns = [
    path('methods/', api_views.PaymentMethodListView.as_view(), name='payment-methods'),
    path('user/payments/gateways/', api_views_v2.AvailablePaymentGatewaysAPIView.as_view(), name='available-gateways'),
    path('user/payments/pesapal/initiate/', api_views_v2.InitiatePesapalPaymentAPIView.as_view(), name='pesapal-initiate'),
    path('pesapal/callback/', api_views_v2.PesapalUserCallbackView.as_view(), name='pesapal-callback'),
    path('pesapal/ipn/', api_views_v2.PesapalIPNAPIView.as_view(), name='pesapal-ipn'),
    path('history/', api_views.TransactionHistoryView.as_view(), name='transaction-history'),
    path('invoices/<uuid:transaction_id>/download/', api_views.DownloadInvoiceView.as_view(), name='download-invoice'),
]