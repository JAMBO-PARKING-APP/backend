from django.db.models import Sum, Count, Q
from django.utils import timezone
from decimal import Decimal
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from apps.common.constants import ParkingStatus, SlotStatus
from apps.payments.models import WalletTransaction
from apps.enforcement.models import Violation
from .models import Zone, ParkingSlot, ParkingSession
from .serializers import (
    OwnerZoneSerializer, 
    OwnerParkingSessionSerializer, 
    OwnerParkingSlotSerializer,
    OwnerViolationReportSerializer
)

class OwnerZoneMixin:
    """Mixin to ensure owner can only access their own zones"""
    def get_queryset(self):
        return Zone.objects.filter(owner=self.request.user, is_active=True)

class OwnerZoneListView(OwnerZoneMixin, generics.ListAPIView):
    """List zones owned by the current user"""
    serializer_class = OwnerZoneSerializer
    permission_classes = [IsAuthenticated]

class OwnerZoneUpdateView(OwnerZoneMixin, generics.UpdateAPIView):
    """Update zone details for owner"""
    serializer_class = OwnerZoneSerializer
    permission_classes = [IsAuthenticated]

class OwnerDashboardAPIView(APIView):
    """Provides high-level metrics for an owner's zones"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        owner = request.user
        zones = Zone.objects.filter(owner=owner)
        
        if not zones.exists():
            return Response({
                'total_zones': 0,
                'active_sessions': 0,
                'total_capacity': 0,
                'total_occupancy_rate': 0,
                'total_earnings': 0
            })

        active_sessions_count = ParkingSession.objects.filter(
            zone__in=zones, status=ParkingStatus.ACTIVE
        ).count()
        
        total_capacity = zones.aggregate(sum_cap=Sum('total_slots'))['sum_cap'] or 0
        occupancy_rate = (active_sessions_count / total_capacity * 100) if total_capacity > 0 else 0
        total_earnings = WalletTransaction.objects.filter(
            user=owner,
            transaction_type='earning',
            status='completed'
        ).aggregate(total=Sum('amount'))['total'] or 0

        return Response({
            'total_zones': zones.count(),
            'active_sessions': active_sessions_count,
            'total_capacity': total_capacity,
            'total_occupancy_rate': round(occupancy_rate, 2),
            'total_earnings': float(total_earnings)
        })

class OwnerSessionsListView(generics.ListAPIView):
    """Lists parking sessions for an owner's zone"""
    serializer_class = OwnerParkingSessionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        zone_id = self.kwargs.get('zone_id')
        if not Zone.objects.filter(id=zone_id, owner=self.request.user).exists():
            return ParkingSession.objects.none()
            
        queryset = ParkingSession.objects.filter(zone_id=zone_id).order_by('-start_time')
        
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
            
        overdue = self.request.query_params.get('overdue')
        if overdue == 'true':
            queryset = [s for s in queryset if s.is_overdue]
            
        return queryset

class OwnerSlotListView(generics.ListAPIView):
    """View all slots in an owner's zone"""
    serializer_class = OwnerParkingSlotSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        zone_id = self.kwargs.get('zone_id')
        if not Zone.objects.filter(id=zone_id, owner=self.request.user).exists():
            return ParkingSlot.objects.none()
        return ParkingSlot.objects.filter(zone_id=zone_id).order_by('slot_code')

class OwnerSlotUpdateView(generics.UpdateAPIView):
    """Update status of a specific slot (e.g. MAINTENANCE)"""
    serializer_class = OwnerParkingSlotSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return ParkingSlot.objects.filter(zone__owner=self.request.user)

class OwnerFinancialReportView(APIView):
    """Aggregates earnings for owner zones"""
    permission_classes = [IsAuthenticated]

    def get(self, request, zone_id):
        owner = request.user
        if not Zone.objects.filter(id=zone_id, owner=owner).exists():
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
            
        earnings = WalletTransaction.objects.filter(
            user=owner,
            transaction_type='earning',
            parking_session__zone_id=zone_id,
            status='completed'
        ).extra(select={'day': 'date(created_at)'}).values('day').annotate(
            total=Sum('amount'),
            count=Count('id')
        ).order_by('-day')

        return Response({
            'zone_id': zone_id,
            'daily_earnings': earnings
        })

class OwnerReportViolationAPIView(APIView):
    """Allows owners to report vehicles in their zones"""
    permission_classes = [IsAuthenticated]

    def post(self, request, zone_id):
        if not Zone.objects.filter(id=zone_id, owner=request.user).exists():
            return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
            
        serializer = OwnerViolationReportSerializer(data=request.data)
        if serializer.is_valid():
            session_id = serializer.validated_data['session_id']
            try:
                session = ParkingSession.objects.get(id=session_id, zone_id=zone_id)
                
                if Violation.objects.filter(parking_session=session, is_paid=False).exists():
                    return Response({'error': 'Active violation already exists for this session'}, status=status.HTTP_400_BAD_REQUEST)

                violation_type = serializer.validated_data['violation_type']
                description = serializer.validated_data.get('description', f'Reported by Zone Owner for session {session_id}')
                violation = Violation.objects.create(
                    vehicle=session.vehicle,
                    zone=session.zone,
                    parking_session=session,
                    violation_type=violation_type,
                    description=description,
                    fine_amount=Decimal('50.00'), 
                    latitude=session.zone.latitude,
                    longitude=session.zone.longitude,
                    officer=None 
                )
                return Response({
                    'message': 'Violation reported successfully',
                    'violation_id': violation.id
                }, status=status.HTTP_201_CREATED)
                
            except ParkingSession.DoesNotExist:
                return Response({'error': 'Session not found in this zone'}, status=status.HTTP_404_NOT_FOUND)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
