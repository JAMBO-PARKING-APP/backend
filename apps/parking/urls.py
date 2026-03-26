from django.urls import path
from . import api_views, invoice_views, qr_payment_views

urlpatterns = [
    path('zones/', api_views.ZoneListView.as_view(), name='zones'),
    path('zones/<uuid:zone_id>/availability/', api_views.ZoneAvailabilityView.as_view(), name='zone-availability'),
    path('sessions/start/', api_views.StartParkingView.as_view(), name='start-parking'),
    path('sessions/extend/', api_views.ExtendParkingView.as_view(), name='extend-parking'),
    path('sessions/end/', api_views.EndParkingView.as_view(), name='end-parking'),
    path('sessions/active/', api_views.ActiveSessionView.as_view(), name='active-session'),
    path('reservations/', api_views.ReservationListCreateView.as_view(), name='reservations'),
    path('applications/', api_views.ZoneApplicationCreateView.as_view(), name='zone-application'),
    path('owner/zones/', api_views.OwnerZoneListView.as_view(), name='owner-zones'),
    path('owner/zones/<uuid:pk>/', api_views.OwnerZoneUpdateView.as_view(), name='owner-zone-detail'),
    
    # Invoices & Public QR Payments
    path('invoice/<uuid:session_id>/', invoice_views.DownloadInvoiceView.as_view(), name='download-invoice'),
    path('pay/zone/<uuid:zone_id>/', qr_payment_views.PublicZonePaymentLandingView.as_view(), name='public-zone-payment'),
    path('pay/callback/', qr_payment_views.PublicPaymentCallbackView.as_view(), name='public-payment-callback'),
]