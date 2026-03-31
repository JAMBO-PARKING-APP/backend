from django.urls import path
from . import api_views, owner_views, invoice_views, qr_payment_views

urlpatterns = [
    path('zones/', api_views.ZoneListView.as_view(), name='zones'),
    path('zones/<uuid:zone_id>/availability/', api_views.ZoneAvailabilityView.as_view(), name='zone-availability'),
    path('sessions/start/', api_views.StartParkingView.as_view(), name='start-parking'),
    path('sessions/extend/', api_views.ExtendParkingView.as_view(), name='extend-parking'),
    path('sessions/end/', api_views.EndParkingView.as_view(), name='end-parking'),
    path('sessions/active/', api_views.ActiveSessionView.as_view(), name='active-session'),
    path('reservations/', api_views.ReservationListCreateView.as_view(), name='reservations'),
    path('applications/', api_views.ZoneApplicationCreateView.as_view(), name='zone-application'),
    path('owner/dashboard/', owner_views.OwnerDashboardAPIView.as_view(), name='owner-dashboard'),
    path('owner/zones/', owner_views.OwnerZoneListView.as_view(), name='owner-zones'),
    path('owner/zones/<uuid:pk>/', owner_views.OwnerZoneUpdateView.as_view(), name='owner-zone-detail'),
    path('owner/zones/<uuid:zone_id>/sessions/', owner_views.OwnerSessionsListView.as_view(), name='owner-zone-sessions'),
    path('owner/zones/<uuid:zone_id>/slots/', owner_views.OwnerSlotListView.as_view(), name='owner-zone-slots'),
    path('owner/slots/<uuid:pk>/', owner_views.OwnerSlotUpdateView.as_view(), name='owner-slot-update'),
    path('owner/zones/<uuid:zone_id>/financials/', owner_views.OwnerFinancialReportView.as_view(), name='owner-zone-financials'),
    path('owner/zones/<uuid:zone_id>/report-violation/', owner_views.OwnerReportViolationAPIView.as_view(), name='owner-report-violation'),
    path('invoice/<uuid:session_id>/', invoice_views.DownloadInvoiceView.as_view(), name='download-invoice'),
    path('pay/zone/<uuid:zone_id>/', qr_payment_views.PublicZonePaymentLandingView.as_view(), name='public-zone-payment'),
    path('pay/callback/', qr_payment_views.PublicPaymentCallbackView.as_view(), name='public-payment-callback'),
]