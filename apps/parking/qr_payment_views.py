from django.shortcuts import render, redirect
from django.views import View
from django.urls import reverse
from .models import Zone, ParkingSession
from apps.payments.pesapal_service import PesapalService
from decimal import Decimal
from django.utils import timezone
import uuid

class PublicZonePaymentLandingView(View):
    """
    Landing page for QR code scans. Allows guests to pay for parking.
    """
    def get(self, request, zone_id):
        zone = Zone.objects.get(id=zone_id, is_active=True)
        return render(request, 'parking/public_payment_landing.html', {'zone': zone})

    def post(self, request, zone_id):
        zone = Zone.objects.get(id=zone_id, is_active=True)
        plate = request.POST.get('license_plate', '').upper()
        duration_hours = Decimal(request.POST.get('duration', '1'))
        
        if not plate:
             return render(request, 'parking/public_payment_landing.html', {
                 'zone': zone, 
                 'error': 'License plate is required'
             })

        cost = (zone.hourly_rate * duration_hours).quantize(Decimal('0.01'))
        
        pesapal = PesapalService()
        callback_url = request.build_absolute_uri(reverse('public-payment-callback'))
        
        # Create a mock user for the guest payment
        class GuestUser:
            def __init__(self, phone, email):
                self.id = uuid.uuid4()
                self.phone = phone
                self.email = email
                self.first_name = "Guest"
                self.last_name = "User"
            def get_full_name(self):
                return "Guest User"

        guest_user = GuestUser(phone="", email="guest@jambopark.com")
        
        order_data = pesapal.create_payment(
            amount=float(cost),
            merchant_reference=f"GUEST-{plate}-{int(timezone.now().timestamp())}",
            description=f"Guest Parking: {plate} at {zone.name}",
            user=guest_user,
            currency=zone.country.currency if zone.country else "UGX"
        )
        
        if order_data and 'redirect_url' in order_data:
            request.session['guest_plate'] = plate
            request.session['guest_zone_id'] = str(zone.id)
            request.session['guest_duration_hours'] = float(duration_hours)
            request.session['guest_cost'] = float(cost)
            
            return redirect(order_data['redirect_url'])
        
        return render(request, 'parking/public_payment_landing.html', {
            'zone': zone, 
            'error': 'Failed to initiate payment. Please try again.'
        })

class PublicPaymentCallbackView(View):
    """
    Handles payment success for guest users.
    """
    def get(self, request):
        order_tracking_id = request.GET.get('OrderTrackingId')
        merchant_reference = request.GET.get('OrderMerchantReference')
        plate = request.session.get('guest_plate')
        zone_id = request.session.get('guest_zone_id')
        duration = request.session.get('guest_duration_hours')
        cost = request.session.get('guest_cost')
        
        if all([plate, zone_id, duration]):
            zone = Zone.objects.get(id=zone_id)
            planned_end = timezone.now() + timezone.timedelta(hours=duration)
            ParkingSession.objects.create(
                guest_license_plate=plate,
                zone=zone,
                start_time=timezone.now(),
                planned_end_time=planned_end,
                estimated_cost=Decimal(str(cost)),
                status='active'
            )
            
            return render(request, 'parking/payment_success.html', {
                'plate': plate,
                'planned_end': planned_end
            })
            
        return render(request, 'parking/payment_error.html')
