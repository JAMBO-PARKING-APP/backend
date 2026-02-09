from django.urls import path
from . import api_views

urlpatterns = [
    path('methods/', api_views.PaymentMethodListView.as_view(), name='payment-methods'),
    path('init/', api_views.InitPaymentView.as_view(), name='init-payment'),
    path('webhook/', api_views.PaymentWebhookView.as_view(), name='payment-webhook'),
    path('history/', api_views.TransactionHistoryView.as_view(), name='transaction-history'),
    path('invoices/<uuid:transaction_id>/download/', api_views.DownloadInvoiceView.as_view(), name='download-invoice'),
]