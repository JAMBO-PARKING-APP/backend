from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.renderers import TemplateHTMLRenderer
from django.template.loader import render_to_string
from apps.parking.models import ParkingSession
from rest_framework.permissions import AllowAny

class DownloadInvoiceView(APIView):
    """
    Returns a simple HTML invoice for a parking session.
    Using AllowAny because session_id is a secure UUID4 and acts as an access token.
    """
    permission_classes = [AllowAny]
    renderer_classes = [TemplateHTMLRenderer]

    def get(self, request, session_id):
        session = get_object_or_404(ParkingSession, id=session_id)
        
        # The session ID is a UUID, which is secure enough for sharing the invoice link.

        context = {
            'session': session,
            'plate': session.vehicle.license_plate if session.vehicle else session.guest_license_plate,
            'duration_hours': round(session.duration_minutes / 60, 2),
            'cost': session.final_cost or session.estimated_cost,
        }
        
        html = render_to_string('parking/invoice_template.html', context)
        return HttpResponse(html)
