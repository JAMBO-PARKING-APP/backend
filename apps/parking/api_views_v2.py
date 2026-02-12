"""
Parking App API Endpoints for User App
- Zone listing and search
- Parking session management
- Reservations
- Real-time availability
"""

from datetime import timedelta
import logging
from django.utils import timezone
from django.db import transaction
from decimal import Decimal
from django.db.models import Q
from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.constants import ParkingStatus, SlotStatus
from .models import Zone, ParkingSlot, ParkingSession, Reservation
from .serializers_v2 import (
    ZoneListSerializer, ZoneDetailSerializer, ParkingSessionSerializer,
    ReservationSerializer, StartParkingSerializer, EndParkingSerializer,
    CreateReservationSerializer
)
from apps.payments.models import WalletTransaction

class ZoneListAPIView(generics.ListAPIView):
    """List all active parking zones"""
    queryset = Zone.objects.filter(is_active=True)
    serializer_class = ZoneListSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Zone.objects.filter(is_active=True)
        
        # Search by name
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(Q(name__icontains=search) | Q(description__icontains=search))
        
        # Filter by price range
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        if min_price:
            queryset = queryset.filter(hourly_rate__gte=float(min_price))
        if max_price:
            queryset = queryset.filter(hourly_rate__lte=float(max_price))
        
        # Filter by availability
        available_only = self.request.query_params.get('available_only', 'false').lower() == 'true'
        if available_only:
            queryset = queryset.exclude(slots__status=SlotStatus.AVAILABLE, slots__isnull=False).distinct()
        
        return queryset

class ZoneDetailAPIView(generics.RetrieveAPIView):
    """Get detailed information about a specific zone"""
    queryset = Zone.objects.filter(is_active=True)
    serializer_class = ZoneDetailSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'pk'

class ZoneAvailabilityAPIView(APIView):
    """Get real-time availability information for a zone"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request, zone_id):
        try:
            zone = Zone.objects.get(id=zone_id, is_active=True)
            
            available_slots = zone.available_slots_count
            occupied_slots = zone.occupied_slots_count
            reserved_slots = zone.slots.filter(status=SlotStatus.RESERVED).count()
            disabled_slots = zone.slots.filter(status=SlotStatus.DISABLED).count()
            total_slots = zone.capacity
            
            return Response({
                'zone_id': zone.id,
                'zone_name': zone.name,
                'available_slots': available_slots,
                'occupied_slots': occupied_slots,
                'reserved_slots': reserved_slots,
                'disabled_slots': disabled_slots,
                'total_slots': total_slots,
                'capacity': total_slots,
                'occupancy_rate': round(zone.occupancy_rate, 2),
                'hourly_rate': float(zone.hourly_rate),
                'latitude': float(zone.latitude),
                'longitude': float(zone.longitude),
                'radius_meters': zone.radius_meters
            }, status=status.HTTP_200_OK)
        except Zone.DoesNotExist:
            return Response({
                'error': 'Zone not found'
            }, status=status.HTTP_404_NOT_FOUND)

class StartParkingAPIView(APIView):
    """Start a parking session"""
    permission_classes = [IsAuthenticated]
    
    @transaction.atomic
    def post(self, request):
        serializer = StartParkingSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            vehicle = request.user.vehicles.get(id=serializer.validated_data['vehicle_id'], is_active=True)
            zone = Zone.objects.get(id=serializer.validated_data['zone_id'], is_active=True)
            duration_hours = float(serializer.validated_data.get('duration_hours', 1))
            logger = logging.getLogger(__name__)
            
            # Check for active session
            active_session = ParkingSession.objects.filter(
                vehicle=vehicle,
                status=ParkingStatus.ACTIVE
            ).first()
            
            if active_session:
                return Response({
                    'error': 'Vehicle already has an active parking session',
                    'session': ParkingSessionSerializer(active_session).data
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Handle slot assignment
            parking_slot = None
            slot_id = serializer.validated_data.get('slot_id')
            
            if slot_id:
                try:
                    parking_slot = ParkingSlot.objects.get(
                        id=slot_id,
                        zone=zone,
                        status=SlotStatus.AVAILABLE
                    )
                except ParkingSlot.DoesNotExist:
                    return Response({
                        'error': 'Selected parking slot is not available'
                    }, status=status.HTTP_400_BAD_REQUEST)
            else:
                # Auto-assign first available slot
                parking_slot = zone.slots.filter(status=SlotStatus.AVAILABLE).first()
                if not parking_slot:
                    return Response({
                        'error': 'No available slots in this zone'
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            # Update slot status
            parking_slot.status = SlotStatus.OCCUPIED
            parking_slot.save()
            
            # Create parking session with proper decimal handling
            planned_end = timezone.now() + timedelta(hours=duration_hours)
            estimated_cost = zone.hourly_rate * Decimal(str(duration_hours))
            logger.debug("Starting parking: user=%s vehicle=%s zone=%s duration_hours=%s planned_end=%s estimated_cost=%s",
                         request.user.id, vehicle.id, zone.id, duration_hours, planned_end.isoformat(), str(estimated_cost))
            
            payment_method = serializer.validated_data.get('payment_method', 'wallet')
            
            if payment_method == 'wallet':
                if request.user.wallet_balance < estimated_cost:
                    return Response({
                        'error': f'Insufficient wallet balance. Required: UGX {estimated_cost}, Available: UGX {request.user.wallet_balance}'
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                # Deduct from wallet
                request.user.wallet_balance -= estimated_cost
                request.user.save()
                
                # Create wallet transaction
                wallet_tx = WalletTransaction.objects.create(
                    user=request.user,
                    amount=estimated_cost,
                    transaction_type='payment',
                    status='completed',
                    description=f'Parking payment for zone {zone.name}'
                )
                
                # Send payment success notification
                from apps.notifications.notification_triggers import notify_payment_success
                notify_payment_success(wallet_tx)

            session = ParkingSession.objects.create(
                vehicle=vehicle,
                zone=zone,
                parking_slot=parking_slot,
                planned_end_time=planned_end,
                estimated_cost=estimated_cost
            )
            
            # Send parking session started notification
            from apps.notifications.notification_triggers import notify_parking_started
            notify_parking_started(session)
            
            return Response({
                'message': 'Parking session started successfully',
                'session': ParkingSessionSerializer(session).data
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            print(f"DEBUG ERROR: {str(e)}")
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

class EndParkingAPIView(APIView):
    """End an active parking session"""
    permission_classes = [IsAuthenticated]
    
    @transaction.atomic
    def post(self, request):
        session_id = request.data.get('session_id')
        
        if not session_id:
            return Response({
                'error': 'session_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            session = ParkingSession.objects.get(
                id=session_id,
                vehicle__user=request.user,
                status=ParkingStatus.ACTIVE
            )
            
            # End session using the model method (includes refund logic)
            session.end_session()
            
            # Send push notification about session end
            from apps.notifications.notification_triggers import notify_parking_ended
            notify_parking_ended(session)
            
            return Response({
                'message': 'Parking session ended successfully',
                'session': ParkingSessionSerializer(session).data,
                'amount_due': float(session.final_cost)
            }, status=status.HTTP_200_OK)
            
        except ParkingSession.DoesNotExist:
            return Response({
                'error': 'Parking session not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            print(f"DEBUG ERROR: {str(e)}")
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

class ExtendParkingAPIView(APIView):
    """Extend an active parking session"""
    permission_classes = [IsAuthenticated]
    
    @transaction.atomic
    def post(self, request):
        session_id = request.data.get('session_id')
        additional_hours = float(request.data.get('additional_hours', 1))
        
        if not session_id:
            return Response({
                'error': 'session_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            session = ParkingSession.objects.get(
                id=session_id,
                vehicle__user=request.user,
                status=ParkingStatus.ACTIVE
            )
            
            # Update planned end time
            session.planned_end_time += timedelta(hours=additional_hours)
            
            # Update estimated cost with proper decimal handling
            additional_cost = session.zone.hourly_rate * Decimal(str(additional_hours))
            session.estimated_cost += additional_cost
            
            session.save()
            
            return Response({
                'message': 'Parking session extended successfully',
                'session': ParkingSessionSerializer(session).data,
                'new_end_time': session.planned_end_time,
                'additional_cost': float(additional_cost)
            }, status=status.HTTP_200_OK)
            
        except ParkingSession.DoesNotExist:
            return Response({
                'error': 'Parking session not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            print(f"DEBUG ERROR: {str(e)}")
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

class CancelParkingSessionAPIView(APIView):
    """Cancel an active parking session and refund remaining time to wallet"""
    permission_classes = [IsAuthenticated]
    
    @transaction.atomic
    def post(self, request):
        session_id = request.data.get('session_id')
        
        if not session_id:
            return Response({
                'error': 'session_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            session = ParkingSession.objects.get(
                id=session_id,
                vehicle__user=request.user,
                status=ParkingStatus.ACTIVE
            )
            
            # Perform cancellation and get refund amount
            refund_amount = session.cancel_session()
            
            if refund_amount > 0:
                # Credit user wallet
                user = request.user
                user.wallet_balance += refund_amount
                user.save()
                
                # Create wallet transaction record
                WalletTransaction.objects.create(
                    user=user,
                    amount=refund_amount,
                    transaction_type='refund',
                    description=f"Refund for cancelled session at {session.zone.name}",
                    parking_session=session
                )
            
            return Response({
                'message': 'Parking session cancelled successfully',
                'refund_amount': float(refund_amount),
                'new_balance': float(request.user.wallet_balance),
                'session': ParkingSessionSerializer(session).data
            }, status=status.HTTP_200_OK)
            
        except ParkingSession.DoesNotExist:
            return Response({
                'error': 'Active parking session not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

class UserParkingSessionsAPIView(generics.ListAPIView):
    """List user's parking sessions (active and history)"""
    permission_classes = [IsAuthenticated]
    serializer_class = ParkingSessionSerializer
    
    def get_queryset(self):
        user_vehicles = self.request.user.vehicles.filter(is_active=True)
        
        # Get filter parameter
        session_type = self.request.query_params.get('type', 'all')
        
        queryset = ParkingSession.objects.filter(vehicle__in=user_vehicles)
        
        if session_type == 'active':
            queryset = queryset.filter(status=ParkingStatus.ACTIVE)
        elif session_type == 'completed':
            queryset = queryset.filter(status=ParkingStatus.COMPLETED)
        elif session_type == 'expired':
            queryset = queryset.filter(status=ParkingStatus.EXPIRED)
        
        return queryset.order_by('-created_at')

class CreateReservationAPIView(APIView):
    """Create a parking reservation"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        serializer = CreateReservationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            vehicle = request.user.vehicles.get(id=serializer.validated_data['vehicle_id'], is_active=True)
            zone = Zone.objects.get(id=serializer.validated_data['zone_id'], is_active=True)
            
            # Validate times
            # Support both new and old field names for backward compatibility during migration
            start_time = serializer.validated_data.get('reserved_from') or serializer.validated_data.get('start_time')
            end_time = serializer.validated_data.get('reserved_until') or serializer.validated_data.get('end_time')
            
            if not start_time or not end_time:
                 # Should be caught by serializer, but just in case
                 return Response({'error': 'Start and end times are required'}, status=status.HTTP_400_BAD_REQUEST)
            
            if start_time >= end_time:
                return Response({
                    'error': 'End time must be after start time'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Relaxed validation: Allow up to 10 mins in the past to account for slow networks/clocks
            if start_time < timezone.now() - timedelta(minutes=10):
                return Response({
                    'error': 'Cannot create reservation in the past'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Calculate cost
            duration_seconds = (end_time - start_time).total_seconds()
            duration_hours = Decimal(str(duration_seconds / 3600))
            if duration_hours < Decimal('0.25'): # Minimum 15 mins
                duration_hours = Decimal('0.25')
            
            cost = (duration_hours * zone.hourly_rate).quantize(Decimal('0.01'))

            # Check for existing pending reservation
            # Avoid duplicates if user retries creation without paying
            from apps.common.constants import TransactionStatus
            existing_reservation = Reservation.objects.filter(
                vehicle=vehicle,
                zone=zone,
                is_active=True,
                reserved_from=start_time,
                reserved_until=end_time
            ).prefetch_related('transactions').first()

            if existing_reservation:
                 # Check if paid
                 has_payment = existing_reservation.transactions.filter(status=TransactionStatus.COMPLETED).exists()
                 if not has_payment:
                     return Response({
                        'message': 'Pending reservation found',
                        'reservation': ReservationSerializer(existing_reservation).data
                    }, status=status.HTTP_200_OK)

            # Create reservation
            reservation = Reservation.objects.create(
                vehicle=vehicle,
                zone=zone,
                reserved_from=start_time,
                reserved_until=end_time,
                cost=cost
            )
            
            return Response({
                'message': 'Reservation created successfully',
                'reservation': ReservationSerializer(reservation).data
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

class UserReservationsAPIView(generics.ListAPIView):
    """List user's parking reservations"""
    permission_classes = [IsAuthenticated]
    serializer_class = ReservationSerializer
    
    def get_queryset(self):
        user_vehicles = self.request.user.vehicles.filter(is_active=True)
        return Reservation.objects.filter(vehicle__in=user_vehicles).order_by('reserved_from')

class CancelReservationAPIView(APIView):
    """Cancel a reservation"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, reservation_id):
        try:
            reservation = Reservation.objects.get(
                id=reservation_id,
                vehicle__user=request.user
            )
            
            if not reservation.is_active:
                return Response({
                    'error': 'Reservation is already inactive or cancelled'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            reservation.is_active = False
            reservation.save()
            
            return Response({
                'message': 'Reservation cancelled successfully',
                'reservation': ReservationSerializer(reservation).data
            }, status=status.HTTP_200_OK)
            
        except Reservation.DoesNotExist:
            return Response({
                'error': 'Reservation not found'
            }, status=status.HTTP_404_NOT_FOUND)
