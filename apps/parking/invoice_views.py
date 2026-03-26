from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.views import View
from django.template.loader import render_to_string
from apps.parking.models import ParkingSession

class DownloadInvoiceView(View):
    """
    Returns a simple HTML invoice for a parking session.
    In a real-world scenario, this would use a library like reportlab or xhtml2pdf.
    """
    def get(self, request, session_id):
        session = get_object_or_404(ParkingSession, id=session_id)
        
        # Security check: Ensure user owns the vehicle or is an admin/owner
        if not (request.user.is_staff or (session.vehicle and session.vehicle.user == request.user)):
             # For guest sessions, we might allow access via a signed token,
             # but for now, we'll keep it simple for authenticated users.
             if not session.guest_license_plate:
                return HttpResponse("Unauthorized", status=403)

        context = {
            'session': session,
            'plate': session.vehicle.license_plate if session.vehicle else session.guest_license_plate,
            'duration_hours': round(session.duration_minutes / 60, 2),
            'cost': session.final_cost or session.estimated_cost,
        }
        
        # Return a simple HTML invoice
        html = render_to_string('parking/invoice_template.html', context)
        return HttpResponse(html)
