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
from django.core.cache import caches

from apps.common.constants import ParkingStatus, SlotStatus
from .models import Zone, ParkingSlot, ParkingSession, Reservation, ZoneApplication
from .serializers_v2 import (
    ZoneListSerializer, ZoneDetailSerializer, ParkingSessionSerializer,
    ReservationSerializer, StartParkingSerializer, EndParkingSerializer,
    CreateReservationSerializer, ZoneApplicationSerializer, OwnerZoneSerializer
)

class ZoneApplicationCreateAPIView(generics.CreateAPIView):
    """Submit a new application to become a zone owner"""
    queryset = ZoneApplication.objects.all()
    serializer_class = ZoneApplicationSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class OwnerZoneListAPIView(generics.ListAPIView):
    """List zones owned by the current user"""
    serializer_class = OwnerZoneSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Zone.objects.filter(owner=self.request.user, is_active=True)

class OwnerZoneUpdateAPIView(generics.UpdateAPIView):
    """Update zone details like hourly_rate for owner"""
    serializer_class = OwnerZoneSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Zone.objects.filter(owner=self.request.user, is_active=True)
from apps.payments.models import WalletTransaction

class ZoneListAPIView(generics.ListAPIView):
    """List all active parking zones"""
    queryset = Zone.objects.filter(is_active=True)
    serializer_class = ZoneListSerializer
    permission_classes = [IsAuthenticated]
    
    def list(self, request, *args, **kwargs):
        search = request.query_params.get('search')
        available_only = request.query_params.get('available_only', 'false').lower() == 'true'
        
        if not search:
            from apps.common.models import get_current_country
            cache = caches['default']
            country = get_current_country()
            country_id = str(country.id) if country else 'none'
            is_staff = request.user.is_staff
            cache_key = f"zone_list_country_{country_id}_staff_{is_staff}_{available_only}_v2"
            cached_data = cache.get(cache_key)
            if cached_data:
                return Response(cached_data)

        queryset = self.get_queryset()
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            data = serializer.data
            if not search:
                cache.set(cache_key, data, timeout=300) 
            return self.get_paginated_response(data)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    def get_queryset(self):
        from django.db.models import Count, Q, Case, When, F, Value
        
        now = timezone.now()
        queryset = Zone.objects.filter(is_active=True).annotate(
            annotated_active_sessions=Count(
                'sessions', 
                filter=Q(sessions__status=ParkingStatus.ACTIVE),
                distinct=True
            ),
            annotated_confirmed_reservations=Count(
                'reservations',
                filter=Q(
                    reservations__status='confirmed',
                    reservations__reserved_from__lte=now,
                    reservations__reserved_until__gt=now
                ),
                distinct=True
            ),
            annotated_capacity=Case(
                When(total_slots__gt=0, then=F('total_slots')),
                default=Count('slots', distinct=True),
            )
        ).annotate(
            annotated_available_slots=Case(
                When(annotated_capacity__gt=(F('annotated_active_sessions') + F('annotated_confirmed_reservations')), 
                     then=F('annotated_capacity') - (F('annotated_active_sessions') + F('annotated_confirmed_reservations'))),
                default=Value(0),
            )
        ).select_related('country')
        
        # Regional filtering is now handled automatically by RegionalManager 
        # using the context set in RegionalContextMiddleware.
        
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(Q(name__icontains=search) | Q(description__icontains=search))
        
        available_only = self.request.query_params.get('available_only', 'false').lower() == 'true'
        if available_only:
            queryset = queryset.filter(annotated_available_slots__gt=0)
        
        return queryset

class ZoneDetailAPIView(generics.RetrieveAPIView):
    """Get detailed information about a specific zone"""
    queryset = Zone.objects.filter(is_active=True).prefetch_related('slots')
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
            occupied_slots = zone.occupied_slots
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
            logger = logging.getLogger(__name__)
            logger.error(f"StartParkingAPIView: Serializer validation failed: {serializer.errors}. Data: {request.data}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            vehicle = request.user.vehicles.get(id=serializer.validated_data['vehicle_id'], is_active=True)
            zone = Zone.objects.get(id=serializer.validated_data['zone_id'], is_active=True)
            duration_hours = float(serializer.validated_data.get('duration_hours', 1))
            logger = logging.getLogger(__name__)
            
            active_session = ParkingSession.objects.filter(
                vehicle=vehicle,
                status=ParkingStatus.ACTIVE
            ).first()
            
            if active_session and active_session.planned_end_time and timezone.now() > active_session.planned_end_time:
                logger.info(f"Self-healing: Ending overdue session {active_session.id} for vehicle {vehicle.license_plate}")
                active_session.end_session()
                active_session = None
            
            if active_session:
                return Response({
                    'error': 'Vehicle already has an active parking session',
                    'session': ParkingSessionSerializer(active_session).data
                }, status=status.HTTP_400_BAD_REQUEST)
            
            parking_slot = None
            slot_id = serializer.validated_data.get('slot_id')
            
            if slot_id:
                try:
                    parking_slot = ParkingSlot.objects.select_for_update().get(
                        id=slot_id,
                        zone=zone,
                        status=SlotStatus.AVAILABLE
                    )
                except ParkingSlot.DoesNotExist:
                    return Response({
                        'error': 'Selected parking slot is not available'
                    }, status=status.HTTP_400_BAD_REQUEST)
            else:
                parking_slot = zone.slots.select_for_update().filter(status=SlotStatus.AVAILABLE).first()
                if not parking_slot:
                    return Response({
                        'error': 'No available slots in this zone'
                    }, status=status.HTTP_400_BAD_REQUEST)

            planned_end = timezone.now() + timedelta(hours=duration_hours)
            estimated_cost = zone.hourly_rate * Decimal(str(duration_hours))
            logger.debug("Starting parking: user=%s vehicle=%s zone=%s duration_hours=%s planned_end=%s estimated_cost=%s",
                         request.user.id, vehicle.id, zone.id, duration_hours, planned_end.isoformat(), str(estimated_cost))
            
            payment_method = serializer.validated_data.get('payment_method', 'wallet')
            
            if payment_method == 'wallet':
                if request.user.wallet_balance < estimated_cost:
                    return Response({
                        'error': f'Insufficient wallet balance. Required: {estimated_cost}, Available: {request.user.wallet_balance}'
                    }, status=status.HTTP_400_BAD_REQUEST)
    
                with transaction.atomic():
                    wallet_tx = request.user.adjust_wallet_balance(
                        -estimated_cost,
                        transaction_type='payment',
                        description=f'Parking payment for zone {zone.name}'
                    )
                    
                    # Mark slot occupied only when session actually starts.
                    parking_slot.status = SlotStatus.OCCUPIED
                    parking_slot.save()
                    
                    session = ParkingSession.objects.create(
                        vehicle=vehicle,
                        zone=zone,
                        parking_slot=parking_slot,
                        planned_end_time=planned_end,
                        estimated_cost=estimated_cost,
                        status=ParkingStatus.ACTIVE
                    )
                    
                    from apps.notifications.notification_triggers import notify_payment_success, notify_parking_started
                    notify_payment_success(wallet_tx)
                    notify_parking_started(session)
                
                return Response({
                    'message': 'Parking session started successfully',
                    'session': ParkingSessionSerializer(session).data
                }, status=status.HTTP_201_CREATED)

            elif payment_method == 'pesapal':
                from apps.payments.pesapal_service import PesapalService
                from apps.payments.models import Transaction as PaymentTransaction
                import uuid
                
                merchant_reference = str(uuid.uuid4())
                country = getattr(request.user, 'country', None)
                pesapal = PesapalService(config_obj=PesapalService.get_config_for_country(country))
                
                processor_response = {
                    'parking_intent': {
                        'vehicle_id': str(vehicle.id),
                        'zone_id': str(zone.id),
                        'slot_id': str(parking_slot.id) if parking_slot else None,
                        'duration_hours': float(duration_hours),
                        'amount': str(estimated_cost)
                    }
                }
                
                trans = PaymentTransaction.objects.create(
                    user=request.user,
                    amount=estimated_cost,
                    idempotency_key=merchant_reference,
                    pesapal_merchant_reference=merchant_reference,
                    status='pending',
                    processor_response=processor_response
                )
                
                payment_response = pesapal.create_payment(
                    amount=estimated_cost,
                    merchant_reference=merchant_reference,
                    description=f"Parking at {zone.name}",
                    user=request.user,
                    currency=country.currency if country else "UGX"
                )
                
                if not payment_response or 'order_tracking_id' not in payment_response:
                    trans.status = 'failed'
                    trans.save()
                    return Response({'error': 'Failed to initiate payment gateway'}, status=status.HTTP_400_BAD_REQUEST)
                
                trans.pesapal_order_tracking_id = payment_response['order_tracking_id']
                trans.save()
                
                return Response({
                    'message': 'Payment required to start session',
                    'payment_required': True,
                    'redirect_url': payment_response['redirect_url'],
                    'order_tracking_id': payment_response['order_tracking_id'],
                    'merchant_reference': merchant_reference
                }, status=status.HTTP_200_OK)
            
            else:
                return Response({'error': f'Unsupported payment method: {payment_method}'}, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            logger = logging.getLogger(__name__)
            logger.error(f"StartParkingAPIView EXCEPTION: {str(e)}", exc_info=True)
            return Response({
                'error': f'Failed to start parking: {str(e)}'
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
            session = ParkingSession.objects.filter(
                id=session_id,
                vehicle__user=request.user
            ).first()
            
            if not session:
                return Response({
                    'error': 'Parking session not found'
                }, status=status.HTTP_404_NOT_FOUND)
                
            if session.status in [ParkingStatus.COMPLETED, ParkingStatus.EXPIRED, ParkingStatus.CANCELLED]:
                return Response({
                    'message': 'Parking session already ended',
                    'session': ParkingSessionSerializer(session).data,
                    'amount_due': float(session.final_cost)
                }, status=status.HTTP_200_OK)
            
            session.end_session()
            
            return Response({
                'message': 'Parking session ended successfully',
                'session': ParkingSessionSerializer(session).data,
                'amount_due': float(session.final_cost)
            }, status=status.HTTP_200_OK)
            
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
            
            additional_hours_decimal = Decimal(str(additional_hours))
            additional_cost = session.zone.hourly_rate * additional_hours_decimal
            
            user = request.user
            if user.wallet_balance < additional_cost:
                return Response({
                    'error': f'Insufficient balance. Need {additional_cost}, but only have {user.wallet_balance}'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            wallet_tx = user.adjust_wallet_balance(
                -additional_cost,
                transaction_type='payment',
                description=f"Extension of {additional_hours}h for {session.zone.name}"
            )
            wallet_tx.metadata.update({'session_id': str(session.id), 'type': 'extension'})
            wallet_tx.save(update_fields=['metadata'])

            session.planned_end_time += timedelta(hours=additional_hours)
            session.estimated_cost += additional_cost
            session.save()
            
            from apps.notifications.notification_triggers import notify_parking_extended
            notify_parking_extended(session, additional_hours, additional_cost)
            
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

            refund_amount = session.cancel_session()
            
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
        queryset = ParkingSession.objects.filter(
            vehicle__user=self.request.user
        ).select_related('zone', 'vehicle', 'parking_slot')
        session_type = self.request.query_params.get('type', 'all')
        if session_type == 'active':
            queryset = queryset.filter(status=ParkingStatus.ACTIVE)
        elif session_type == 'completed':
            queryset = queryset.filter(status=ParkingStatus.COMPLETED)
        elif session_type == 'expired':
            queryset = queryset.filter(status=ParkingStatus.EXPIRED)
        
        return queryset.order_by('-created_at')

from apps.parking.services.reservation_service import ReservationService

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
            start_time = serializer.validated_data.get('reserved_from') or serializer.validated_data.get('start_time')
            end_time = serializer.validated_data.get('reserved_until') or serializer.validated_data.get('end_time')
            
            if not start_time or not end_time:
                 return Response({'error': 'Start and end times are required'}, status=status.HTTP_400_BAD_REQUEST)
            
            if start_time >= end_time:
                return Response({
                    'error': 'End time must be after start time'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            if start_time < timezone.now() - timedelta(minutes=10):
                return Response({
                    'error': 'Cannot create reservation in the past'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            existing_reservation = Reservation.objects.filter(
                vehicle=vehicle,
                zone=zone,
                status='pending_payment',
                reserved_from=start_time,
                reserved_until=end_time
            ).first()

            if existing_reservation:
                 return Response({
                    'message': 'Pending reservation found',
                    'reservation': ReservationSerializer(existing_reservation).data
                }, status=status.HTTP_200_OK)

            reservation = ReservationService.create_reservation(
                vehicle=vehicle,
                zone=zone,
                start_time=start_time,
                end_time=end_time,
                confirm_immediately=serializer.validated_data.get('confirm_immediately', False),
                payment_method=serializer.validated_data.get('payment_method', 'wallet')
            )
            
            return Response({
                'message': 'Reservation created successfully',
                'reservation': ReservationSerializer(reservation).data
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            logger = logging.getLogger(__name__)
            logger.error(f"CreateReservationAPIView: Error: {str(e)}", exc_info=True)
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

class UserReservationsAPIView(generics.ListAPIView):
    """List user's parking reservations"""
    permission_classes = [IsAuthenticated]
    serializer_class = ReservationSerializer
    
    def get_queryset(self):
        user_vehicles = self.request.user.vehicles.filter(is_active=True)
        return Reservation.objects.filter(
            vehicle__in=user_vehicles
        ).select_related('vehicle', 'zone', 'parking_slot').order_by('-created_at')

class CancelReservationAPIView(APIView):
    """Cancel a reservation"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, reservation_id):
        try:
            reservation = Reservation.objects.get(
                id=reservation_id,
                vehicle__user=request.user
            )
            
            ReservationService.cancel_reservation(reservation)
            
            return Response({
                'message': 'Reservation cancelled successfully',
                'reservation': ReservationSerializer(reservation).data
            }, status=status.HTTP_200_OK)
            
        except Reservation.DoesNotExist:
            return Response({
                'error': 'Reservation not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

class ConfirmReservationWalletAPIView(APIView):
    """Confirm a reservation using wallet balance"""
    permission_classes = [IsAuthenticated]
    
    @transaction.atomic
    def post(self, request, reservation_id):
        try:
            reservation = Reservation.objects.get(
                id=reservation_id,
                vehicle__user=request.user
            )
            
            if reservation.status != 'pending_payment':
                return Response({
                    'error': f'Reservation is in status {reservation.status}, not pending payment'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            if request.user.wallet_balance < reservation.cost:
                return Response({
                    'error': 'Insufficient wallet balance'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            ReservationService.confirm_reservation(reservation, payment_method='wallet')
            
            return Response({
                'message': 'Reservation confirmed with wallet',
                'reservation': ReservationSerializer(reservation).data
            }, status=status.HTTP_200_OK)
            
        except Reservation.DoesNotExist:
            return Response({
                'error': 'Reservation not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)
