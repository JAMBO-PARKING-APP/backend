from django.urls import path
from . import api_views
from . import pesapal_views

urlpatterns = [
    path('methods/', api_views.PaymentMethodListView.as_view(), name='payment-methods'),
    path('pesapal/initiate/', pesapal_views.PesapalInitPaymentView.as_view(), name='pesapal-init'),
    path('pesapal/callback/', pesapal_views.PesapalCallbackView.as_view(), name='pesapal-callback'),
    path('pesapal/ipn/', pesapal_views.PesapalIPNView.as_view(), name='pesapal-ipn'),
    path('history/', api_views.TransactionHistoryView.as_view(), name='transaction-history'),
    path('invoices/<uuid:transaction_id>/download/', api_views.DownloadInvoiceView.as_view(), name='download-invoice'),
]