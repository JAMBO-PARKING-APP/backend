import logging
from decimal import Decimal
from django.contrib.auth import authenticate
from django.db.models import Sum, Count, Avg
from django.utils import timezone
from datetime import timedelta

from rest_framework import status, generics
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import ZoneApplicationPublic, OwnerBankDetails
from .serializers import (
    ZoneApplicationPublicSerializer,
    ApplicationStatusSerializer,
    OwnerBankDetailsSerializer,
)

logger = logging.getLogger(__name__)


class PublicApplyView(APIView):
    """POST /api/partner/apply/ — submit a zone application (no auth required)"""
    authentication_classes = []   
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ZoneApplicationPublicSerializer(data=request.data)
        if serializer.is_valid():
            application = serializer.save()
            return Response({
                'application_id': str(application.application_id),
                'message': 'Application submitted successfully. You will be notified via email.',
                'status': application.status,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AuthApplyView(APIView):
    """POST /api/partner/zones/apply/ — submit a zone application for logged-in users"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user  
        data = request.data.copy()
        data['applicant_name'] = data.get('applicant_name') or user.full_name or f"{user.first_name} {user.last_name}".strip()
        data['applicant_email'] = data.get('applicant_email') or user.email
        data['applicant_phone'] = data.get('applicant_phone') or user.phone

        serializer = ZoneApplicationPublicSerializer(data=data)
        if serializer.is_valid():
            application = serializer.save()
            return Response({
                'application_id': str(application.application_id),
                'message': 'Add Zone Application submitted successfully. It is now pending approval.',
                'status': application.status,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ApplicationStatusView(APIView):
    """GET /api/partner/status/<application_id>/ — public status check"""
    authentication_classes = []   
    permission_classes = [AllowAny]

    def get(self, request, application_id):
        try:
            application = ZoneApplicationPublic.objects.get(application_id=application_id)
            serializer = ApplicationStatusSerializer(application)
            return Response(serializer.data)
        except ZoneApplicationPublic.DoesNotExist:
            return Response(
                {'error': 'Application not found. Please check your Application ID.'},
                status=status.HTTP_404_NOT_FOUND
            )


class PartnerLoginView(APIView):
    """POST /api/partner/login/ — login for zone owners, returns JWT"""
    authentication_classes = []   
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        password = request.data.get('password', '')

        if not email or not password:
            return Response({'error': 'Email and password are required.'},
                            status=status.HTTP_400_BAD_REQUEST)

        from apps.accounts.models import User
        email_clean = email.lower()
        try:
            user = User.objects.get(email__iexact=email_clean)
            print(f"DEBUG LOGIN: Found user for email {email_clean}: {user.phone}")
        except User.DoesNotExist:
            print(f"DEBUG LOGIN: No user found for email {email_clean}")
            return Response({'error': 'Invalid credentials.'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.check_password(password):
            print(f"DEBUG LOGIN: Password check failed for user {email}")
            return Response({'error': 'Invalid credentials.'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_active:
            print(f"DEBUG LOGIN: User {email} is inactive")
            return Response({'error': 'Account is disabled.'}, status=status.HTTP_403_FORBIDDEN)

        has_zones = user.owned_zones.filter(is_active=True).exists()
        print(f"DEBUG LOGIN: User {email} has active zones: {has_zones}")
        if not has_zones:
            return Response({'error': 'No active zones linked to this account.'},
                            status=status.HTTP_403_FORBIDDEN)

        refresh = RefreshToken.for_user(user)
        access_token = refresh.access_token
        token_jti = str(access_token.get('jti', ''))
        user.current_session_token = token_jti
        user.save(update_fields=['current_session_token'])
        has_bank_details = OwnerBankDetails.objects.filter(user=user).exists()

        return Response({
            'access': str(access_token),
            'refresh': str(refresh),
            'has_bank_details': has_bank_details,
            'user': {
                'id': str(user.id),
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'full_name': user.full_name,
            }
        })


class BankDetailsView(APIView):
    """GET/POST /api/partner/bank-details/ — save or retrieve bank details"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            details = OwnerBankDetails.objects.get(user=request.user)
            return Response(OwnerBankDetailsSerializer(details).data)
        except OwnerBankDetails.DoesNotExist:
            return Response({'exists': False}, status=status.HTTP_404_NOT_FOUND)

    def post(self, request):
        existing = OwnerBankDetails.objects.filter(user=request.user).first()
        if existing:
            serializer = OwnerBankDetailsSerializer(existing, data=request.data, partial=True)
        else:
            serializer = OwnerBankDetailsSerializer(data=request.data)

        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response({
                'message': 'Bank details saved successfully.',
                'data': serializer.data
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class OwnerDashboardView(APIView):
    """GET /api/partner/dashboard/ — earnings and zone analytics"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        from apps.parking.models import Zone, ParkingSession
        from apps.payments.models import WalletTransaction

        zones = Zone.objects.filter(owner=user, is_active=True)
        if not zones.exists():
            return Response({'error': 'No active zones found.'}, status=status.HTTP_404_NOT_FOUND)

        now = timezone.now()
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        start_of_today = now.replace(hour=0, minute=0, second=0, microsecond=0)
        last_30_days = now - timedelta(days=30)

        total_earnings = WalletTransaction.objects.filter(
            user=user, transaction_type='earning', status='completed'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')

        month_earnings = WalletTransaction.objects.filter(
            user=user, transaction_type='earning', status='completed',
            created_at__gte=start_of_month
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')

        today_earnings = WalletTransaction.objects.filter(
            user=user, transaction_type='earning', status='completed',
            created_at__gte=start_of_today
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')

        zone_ids = list(zones.values_list('id', flat=True))
        today_sessions = ParkingSession.objects.filter(
            zone_id__in=zone_ids,
            start_time__gte=start_of_today
        ).count()

        active_sessions = ParkingSession.objects.filter(
            zone_id__in=zone_ids, status='active'
        ).count()

        from apps.parking.models import Reservation
        total_reservations = Reservation.objects.filter(
            zone_id__in=zone_ids
        ).count()
        pending_reservations = Reservation.objects.filter(
            zone_id__in=zone_ids, status='pending'
        ).count()

        from django.db.models.functions import TruncDate
        daily_earnings = list(
            WalletTransaction.objects.filter(
                user=user, transaction_type='earning', status='completed',
                created_at__gte=last_30_days
            ).annotate(day=TruncDate('created_at'))
            .values('day')
            .annotate(amount=Sum('amount'))
            .order_by('day')
            .values('day', 'amount')
        )

        earnings_chart = [
            {'date': str(item['day']), 'amount': float(item['amount'])}
            for item in daily_earnings
        ]

        zone_data = []
        revenue_by_zone = []
        
        for z in zones:
            zone_data.append({
                'id': str(z.id),
                'name': z.name,
                'total_slots': z.total_slots,
                'hourly_rate': float(z.hourly_rate),
                'commission_rate': float(z.commission_rate),
                'active_sessions': z.active_sessions_count,
                'available_slots': z.available_slots_count,
                'occupancy_rate': round(z.occupancy_rate, 1),
                'supports_reservations': z.supports_reservations,
                'supports_pricing': z.supports_dynamic_pricing,
            })
            
            zone_earnings = ParkingSession.objects.filter(
                zone=z, status='completed'
            ).aggregate(total=Sum('final_cost'))['total'] or Decimal('0')
            
            if zone_earnings > 0:
                revenue_by_zone.append({
                    'name': z.name,
                    'value': float(zone_earnings)
                })

        recent_sessions = ParkingSession.objects.filter(
            zone_id__in=zone_ids
        ).select_related('zone', 'vehicle').order_by('-start_time')[:20]

        sessions_data = [
            {
                'id': str(s.id),
                'zone': s.zone.name,
                'vehicle': s.vehicle.license_plate if s.vehicle else s.guest_license_plate,
                'start_time': s.start_time.isoformat(),
                'status': s.status,
                'final_cost': float(s.final_cost) if s.final_cost else float(s.estimated_cost),
                'is_guest': s.vehicle is None
            }
            for s in recent_sessions
        ]

        recent_reservations = Reservation.objects.filter(
            zone_id__in=zone_ids
        ).select_related('zone', 'vehicle__user').order_by('-reserved_from')[:20]

        reservations_data = [
            {
                'id': str(r.id),
                'zone': r.zone.name,
                'user': r.vehicle.user.full_name or r.vehicle.user.phone,
                'start_time': r.reserved_from.isoformat(),
                'status': r.status,
                'service_fee': float(r.service_fee),
            }
            for r in recent_reservations
        ]

        return Response({
            'summary': {
                'total_earnings': float(total_earnings),
                'month_earnings': float(month_earnings),
                'today_earnings': float(today_earnings),
                'today_sessions': today_sessions,
                'active_sessions': active_sessions,
                'total_reservations': total_reservations,
                'pending_reservations': pending_reservations,
                'zones_count': zones.count(),
            },
            'earnings_chart': earnings_chart,
            'revenue_by_zone': revenue_by_zone,
            'zones': zone_data,
            'recent_sessions': sessions_data,
            'recent_reservations': reservations_data,
        })


class PartnerChangePasswordView(APIView):
    """POST /api/partner/change-password/"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')
        confirm_password = request.data.get('confirm_password')

        if not all([old_password, new_password, confirm_password]):
            return Response({'error': 'All fields are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if not request.user.check_password(old_password):
            return Response({'error': 'Current password is incorrect.'}, status=status.HTTP_400_BAD_REQUEST)

        if new_password != confirm_password:
            return Response({'error': 'New passwords do not match.'}, status=status.HTTP_400_BAD_REQUEST)

        if len(new_password) < 8:
            return Response({'error': 'Password must be at least 8 characters.'}, status=status.HTTP_400_BAD_REQUEST)

        request.user.set_password(new_password)
        request.user.save()

        return Response({'message': 'Password changed successfully. Please log in again.'})
