"""
Enforcement API Endpoints for User App
- View violations
- View violation details and evidence
Officer API Endpoints
- Officer status management (online/offline)
- QR code scanning and logging
- License plate search
- Activity logs
"""

from decimal import Decimal
import logging
from django.db import transaction
from django.utils import timezone
from rest_framework import generics, status, serializers
from rest_framework.decorators import permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiExample
from apps.common.constants import UserRole, ParkingStatus, SlotStatus
from apps.accounts.models import Vehicle
from apps.parking.models import ParkingSession
from apps.notifications.models import NotificationEvent
from .models import Violation, OfficerStatus, OfficerLog, QRCodeScan, GuestParkingSession
from .serializers_v2 import (
    ViolationListSerializer, ViolationDetailSerializer,
    OfficerStatusSerializer, QRCodeScanSerializer, OfficerActionLogV2Serializer,
    VehicleStatusCheckSerializer
)

logger = logging.getLogger(__name__)

class UserViolationsListAPIView(generics.ListAPIView):
    """List all violations for user's vehicles"""
    permission_classes = [IsAuthenticated]
    serializer_class = ViolationListSerializer
    
    def get_queryset(self):
        user_vehicles = self.request.user.vehicles.filter(is_active=True)
        paid_only = self.request.query_params.get('paid_only', 'false').lower() == 'true'
        unpaid_only = self.request.query_params.get('unpaid_only', 'false').lower() == 'true'
        queryset = Violation.objects.filter(vehicle__in=user_vehicles)
        if paid_only:
            queryset = queryset.filter(is_paid=True)
        elif unpaid_only:
            queryset = queryset.filter(is_paid=False)
        
        return queryset.order_by('-created_at')

class ViolationDetailAPIView(generics.RetrieveAPIView):
    """Get detailed information about a specific violation"""
    permission_classes = [IsAuthenticated]
    serializer_class = ViolationDetailSerializer
    lookup_field = 'pk'
    
    def get_queryset(self):
        user_vehicles = self.request.user.vehicles.filter(is_active=True)
        return Violation.objects.filter(vehicle__in=user_vehicles)

class UnpaidViolationsCountAPIView(APIView):
    """Get count of unpaid violations"""
    permission_classes = [IsAuthenticated]
    
    @extend_schema(responses={200: OpenApiExample('Success', value={'unpaid_count': 0, 'total_amount': 0.0})})
    
    def get(self, request):
        user_vehicles = request.user.vehicles.filter(is_active=True)
        count = Violation.objects.filter(
            vehicle__in=user_vehicles,
            is_paid=False
        ).count()
        
        total_amount = sum(
            v.fine_amount for v in Violation.objects.filter(
                vehicle__in=user_vehicles,
                is_paid=False
            )
        )
        
        return Response({
            'unpaid_count': count,
            'total_amount': float(total_amount)
        }, status=status.HTTP_200_OK)

class OfficerStatusToggleAPIView(APIView):
    """Toggle officer online/offline status"""
    permission_classes = [IsAuthenticated]
    serializer_class = OfficerStatusSerializer

    @extend_schema(
        request=serializers.Serializer, 
        responses={200: OpenApiExample('Success', value={'message': '...', 'is_online': True, 'status': {}})},
    )
    
    @transaction.atomic
    def post(self, request):
        officer = request.user
        is_going_online = request.data.get('is_online', True)
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        status_obj, created = OfficerStatus.objects.get_or_create(officer=officer)

        if is_going_online:
            status_obj.is_online = True
            status_obj.went_online_at = timezone.now()
            status_obj.went_offline_at = None
            action = 'online'
        else:
            status_obj.is_online = False
            status_obj.went_offline_at = timezone.now()
            action = 'offline'
        
        if latitude and longitude and str(latitude).strip() and str(longitude).strip():
            from apps.common.utils import truncate_coord
            status_obj.latitude = truncate_coord(latitude)
            status_obj.longitude = truncate_coord(longitude)
        else:
            status_obj.latitude = None
            status_obj.longitude = None
        
        status_obj.save()
        
        OfficerLog.objects.create(
            officer=officer,
            action=action,
            details={
                'status': 'online' if is_going_online else 'offline',
                'latitude': float(latitude) if latitude else None,
                'longitude': float(longitude) if longitude else None,
            },
            latitude=latitude,
            longitude=longitude
        )
        
        return Response({
            'message': f'Officer is now {action}',
            'is_online': status_obj.is_online,
            'status': OfficerStatusSerializer(status_obj).data
        }, status=status.HTTP_200_OK)

class OfficerStatusAPIView(APIView):
    """Get current officer status"""
    permission_classes = [IsAuthenticated]
    serializer_class = OfficerStatusSerializer

    @extend_schema(responses={200: OfficerStatusSerializer})
    
    def get(self, request):
        try:
            status_obj = OfficerStatus.objects.get(officer=request.user)
            return Response(OfficerStatusSerializer(status_obj).data, status=status.HTTP_200_OK)
        except OfficerStatus.DoesNotExist:
            return Response({
                'is_online': False,
                'last_location': None,
                'message': 'Officer is offline (no status record)'
            }, status=status.HTTP_200_OK)

class SearchVehicleByPlateAPIView(APIView):
    """Search vehicle by license plate"""
    permission_classes = [IsAuthenticated]

    @extend_schema(
        parameters=[OpenApiParameter("plate", str, OpenApiParameter.QUERY, description="License plate")],
        responses={200: OpenApiExample('Success', value={'id': '...', 'license_plate': '...', 'active_session': {}})},
    )
    
    def get(self, request):
        license_plate = request.query_params.get('plate', '').upper()
        
        if not license_plate:
            return Response({
                'error': 'License plate is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            vehicle = Vehicle.objects.get(license_plate=license_plate)
            active_session = ParkingSession.objects.filter(
                vehicle=vehicle,
                status=ParkingStatus.ACTIVE
            ).first()
            
            violations = Violation.objects.filter(
                vehicle=vehicle,
                is_paid=False
            ).count()
            
            response_data = {
                'id': str(vehicle.id),
                'license_plate': vehicle.license_plate,
                'make': vehicle.make,
                'model': vehicle.model,
                'color': vehicle.color,
                'owner_name': vehicle.user.get_full_name() or str(vehicle.user.phone),
                'owner_phone': str(vehicle.user.phone),
                'active_session': None,
                'unpaid_violations': violations,
                'user_id': str(vehicle.user.id),
            }
            
            if active_session:
                response_data['active_session'] = {
                    'id': str(active_session.id),
                    'zone': active_session.zone.name,
                    'zone_id': str(active_session.zone.id),
                    'started_at': active_session.start_time.isoformat(),
                    'planned_end': active_session.planned_end_time.isoformat(),
                    'estimated_cost': float(active_session.estimated_cost),
                }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Vehicle.DoesNotExist:
            return Response({
                'error': f'Vehicle with plate {license_plate} not found'
            }, status=status.HTTP_404_NOT_FOUND)

class OfficerVehicleStatusAPIView(APIView):
    """
    Officer lookup for vehicle status and fine calculation.
    """
    permission_classes = [IsAuthenticated]
    
    @extend_schema(
        parameters=[OpenApiParameter("plate", str, OpenApiParameter.QUERY, description="License plate")],
        responses={200: VehicleStatusCheckSerializer},
    )
    def get(self, request):
        license_plate = request.query_params.get('plate', '').upper()
        if not license_plate:
            return Response({'error': 'Plate is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            vehicle = Vehicle.objects.get(license_plate=license_plate)
            
            # Find the most recent session (active or recently ended/expired)
            session = ParkingSession.objects.filter(
                vehicle=vehicle
            ).order_by('-created_at').first()
            
            status_text = 'no_active_session'
            overdue_minutes = 0
            suggested_fine = Decimal('0.00')
            planned_end = None
            zone_name = None
            active_session_id = None
            
            if session:
                zone_name = session.zone.name
                planned_end = session.planned_end_time
                
                if session.status == ParkingStatus.ACTIVE:
                    active_session_id = session.id
                    if timezone.now() > session.planned_end_time:
                        status_text = 'overdue'
                        overdue_seconds = (timezone.now() - session.planned_end_time).total_seconds()
                        overdue_minutes = int(overdue_seconds / 60)
                        overdue_hours = Decimal(str(overdue_seconds / 3600))
                        suggested_fine = (overdue_hours * session.zone.hourly_rate).quantize(Decimal('0.01'))
                    else:
                        status_text = 'parked'
                elif session.status == ParkingStatus.EXPIRED:
                    status_text = 'expired'
            
            data = {
                'id': str(vehicle.id),
                'license_plate': vehicle.license_plate,
                'make': vehicle.make,
                'model': vehicle.model,
                'color': vehicle.color,
                'owner_name': vehicle.user.get_full_name() or str(vehicle.user.phone),
                'owner_phone': str(vehicle.user.phone),
                'unpaid_violations': Violation.objects.filter(vehicle=vehicle, is_paid=False).count(),
                'active_session': None,
                'status': status_text,
                'overdue_duration_minutes': overdue_minutes,
                'suggested_fine': float(suggested_fine),
            }
            
            if session and session.status == ParkingStatus.ACTIVE:
                data['active_session'] = {
                    'id': str(session.id),
                    'zone': session.zone.name,
                    'zone_id': str(session.zone.id),
                    'started_at': session.start_time.isoformat(),
                    'planned_end': session.planned_end_time.isoformat(),
                    'estimated_cost': float(session.estimated_cost),
                }
            
            return Response(data, status=status.HTTP_200_OK)
            
        except Vehicle.DoesNotExist:
            return Response({'error': 'Vehicle not found'}, status=status.HTTP_404_NOT_FOUND)

class StartSessionByOfficerAPIView(APIView):
    """Allow enforcement officers to start a parking session for a vehicle"""
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        if request.user.role != UserRole.OFFICER:
            return Response({'error': 'Only officers can perform this action'}, status=status.HTTP_403_FORBIDDEN)
            
        vehicle_id = request.data.get('vehicle_id')
        zone_id = request.data.get('zone_id')
        duration_hours = float(request.data.get('duration_hours', 1.0))
        
        if not all([vehicle_id, zone_id]):
            return Response({'error': 'vehicle_id and zone_id are required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            from apps.parking.models import Zone, ParkingSlot
            from apps.parking.serializers_v2 import ParkingSessionSerializer

            vehicle = Vehicle.objects.get(id=vehicle_id, is_active=True)
            zone = Zone.objects.get(id=zone_id, is_active=True)
            
            active_session = ParkingSession.objects.filter(vehicle=vehicle, status=ParkingStatus.ACTIVE).first()
            if active_session:
                return Response({'error': 'Vehicle already has an active session'}, status=status.HTTP_400_BAD_REQUEST)
                
            parking_slot = zone.slots.filter(status=SlotStatus.AVAILABLE).first()
            if not parking_slot:
                return Response({'error': 'No available slots in this zone'}, status=status.HTTP_400_BAD_REQUEST)
                
            parking_slot.status = SlotStatus.OCCUPIED
            parking_slot.save()
            
            planned_end = timezone.now() + timezone.timedelta(hours=duration_hours)
            estimated_cost = zone.hourly_rate * Decimal(str(duration_hours))
            
            session = ParkingSession.objects.create(
                vehicle=vehicle,
                zone=zone,
                parking_slot=parking_slot,
                start_time=timezone.now(),
                planned_end_time=planned_end,
                estimated_cost=estimated_cost,
                status=ParkingStatus.ACTIVE
            )
            
            # Deduct from user wallet
            try:
                from django.db import transaction as db_transaction
                driver = vehicle.user
                db_transaction.on_commit(lambda: driver.adjust_wallet_balance(
                    amount=-estimated_cost,
                    transaction_type='payment',
                    description=f"Parking payment for {vehicle.license_plate} in {zone.name} (Officer Initiated)",
                    parking_session=session
                ))
                logger.info(f"Queued wallet deduction of {estimated_cost} from user {driver.id} for session {session.id}")
            except Exception as e:
                logger.error(f"Failed to queue wallet deduction for officer-started session: {e}")

            try:
                from apps.notifications.notification_triggers import notify_parking_started
                from django.db import transaction as db_transaction
                db_transaction.on_commit(lambda s=session: notify_parking_started(s))
            except Exception as e:
                logger.error(f"Failed to send parking session notification: {e}")
            
            OfficerLog.objects.create(
                officer=request.user,
                action='manual_session_start',
                details={
                    'vehicle_id': vehicle_id,
                    'zone_id': zone_id,
                    'duration': duration_hours,
                    'session_id': str(session.id)
                }
            )
            
            return Response({
                'message': 'Parking session started successfully',
                'session': ParkingSessionSerializer(session).data
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class CreateGuestParkingSessionAPIView(APIView):
    """Allow enforcement officers to create parking sessions for non-app users (guests)"""
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        if request.user.role != UserRole.OFFICER:
            return Response({'error': 'Only officers can perform this action'}, status=status.HTTP_403_FORBIDDEN)
        
        # Accept both field name variations
        license_plate = (request.data.get('license_plate') or request.data.get('vehicle_plate', '')).upper()
        driver_name = request.data.get('driver_name', '').strip()
        driver_phone = request.data.get('driver_phone', '').strip()
        zone_id = request.data.get('zone_id')
        
        # Handle duration in both minutes and hours
        duration_minutes = request.data.get('duration_minutes')
        duration_hours = request.data.get('duration_hours')
        
        if duration_minutes is not None:
            try:
                duration_hours = float(duration_minutes) / 60.0
            except (ValueError, TypeError):
                return Response(
                    {'error': 'duration_minutes must be a number'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        elif duration_hours is not None:
            duration_hours = float(duration_hours)
        else:
            duration_hours = 1.0
        
        if not all([license_plate, driver_name, zone_id]):
            return Response(
                {'error': 'license_plate (or vehicle_plate), driver_name, and zone_id are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            from apps.parking.models import Zone, ParkingSlot
            
            zone = Zone.objects.get(id=zone_id, is_active=True)
            
            parking_slot = zone.slots.filter(status=SlotStatus.AVAILABLE).first()
            if not parking_slot:
                return Response(
                    {'error': 'No available slots in this zone'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            parking_slot.status = SlotStatus.OCCUPIED
            parking_slot.save()
            
            planned_end = timezone.now() + timezone.timedelta(hours=duration_hours)
            estimated_cost = zone.hourly_rate * Decimal(str(duration_hours))
            
            # Create guest parking session record
            guest_session = GuestParkingSession.objects.create(
                license_plate=license_plate,
                driver_name=driver_name,
                driver_phone=driver_phone,
                zone=zone,
                parking_slot=parking_slot,
                start_time=timezone.now(),
                planned_end_time=planned_end,
                estimated_cost=estimated_cost,
                status=ParkingStatus.ACTIVE,
                officer=request.user
            )
            
            logger.info(
                f"Guest parking session created: plate={license_plate}, "
                f"driver={driver_name}, zone={zone.name}, officer={request.user.id}"
            )
            
            OfficerLog.objects.create(
                officer=request.user,
                action='guest_session_start',
                details={
                    'license_plate': license_plate,
                    'driver_name': driver_name,
                    'zone_id': str(zone_id),
                    'duration': duration_hours,
                    'guest_session_id': str(guest_session.id)
                }
            )
            
            return Response({
                'message': 'Guest parking session created successfully',
                'session_id': str(guest_session.id),
                'amount_due': float(estimated_cost),
                'requires_payment': float(estimated_cost) > 0,
                'payment_url': None,
                'session': {
                    'id': str(guest_session.id),
                    'license_plate': guest_session.license_plate,
                    'driver_name': guest_session.driver_name,
                    'driver_phone': guest_session.driver_phone or '',
                    'zone_name': zone.name,
                    'start_time': guest_session.start_time.isoformat(),
                    'planned_end_time': guest_session.planned_end_time.isoformat(),
                    'estimated_cost': str(guest_session.estimated_cost),
                    'status': guest_session.status,
                }
            }, status=status.HTTP_201_CREATED)
            
        except Zone.DoesNotExist:
            return Response({'error': 'Zone not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            logger.error(f"Failed to create guest parking session: {e}", exc_info=True)
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class ScanQRCodeAPIView(APIView):
    """Log QR code scan and optionally end session"""
    permission_classes = [IsAuthenticated]

    @extend_schema(
        request=serializers.Serializer, 
        responses={200: OpenApiExample('Success', value={'scan_id': '...', 'scan_status': '...', 'session': {}})},
    )
    @transaction.atomic
    def post(self, request):
        officer = request.user
        session_id = request.data.get('session_id')
        qr_data = request.data.get('qr_data')
        end_session = request.data.get('end_session', False)
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')

        logger.debug("QR scan request: officer=%s session_id=%s end_session=%s lat=%s lon=%s",
                     getattr(officer, 'id', None), session_id, end_session, latitude, longitude)

        if not session_id or not qr_data:
            return Response({'error': 'session_id and qr_data are required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            session = ParkingSession.objects.get(id=session_id)

            now = timezone.now()
            logger.debug("Session fetched: id=%s status=%s planned_end=%s now=%s",
                         session.id, session.status, session.planned_end_time.isoformat(), now.isoformat())
            if session.status != ParkingStatus.ACTIVE:
                scan_status = 'already_ended'
            elif session.planned_end_time <= now:
                scan_status = 'expired'
            else:
                scan_status = 'valid'
            from apps.common.utils import truncate_coord
            qr_scan = QRCodeScan.objects.create(
                officer=officer,
                parking_session=session,
                qr_data=qr_data,
                scan_status=scan_status,
                latitude=truncate_coord(latitude),
                longitude=truncate_coord(longitude),
                session_ended=False
            )

            OfficerLog.objects.create(
                officer=officer,
                action='qr_scan',
                details={
                    'session_id': session_id,
                    'vehicle_plate': session.vehicle.license_plate,
                    'scan_status': scan_status,
                    'latitude': float(latitude) if latitude else None,
                    'longitude': float(longitude) if longitude else None,
                },
                latitude=latitude,
                longitude=longitude
            )

            response_data = {
                'scan_id': str(qr_scan.id),
                'scan_status': scan_status,
                'session': {
                    'id': str(session.id),
                    'vehicle': session.vehicle.license_plate,
                    'zone': session.zone.name,
                    'started_at': session.start_time.isoformat(),
                    'planned_end': session.planned_end_time.isoformat(),
                    'status': session.status,
                },
                'message': 'QR code scanned successfully'
            }

            if end_session and scan_status == 'valid':
                session.actual_end_time = timezone.now()
                session.status = ParkingStatus.COMPLETED
                session.save()
                if session.parking_slot:
                    session.parking_slot.status = SlotStatus.AVAILABLE
                    session.parking_slot.save()
                qr_scan.session_ended = True
                qr_scan.save()
                user = session.vehicle.user
                NotificationEvent.objects.create(
                    user=user,
                    title='Parking Session Ended',
                    message=f'Your parking session in {session.zone.name} has been ended by an officer.',
                    type='parking_ended',
                    category='parking',
                    metadata={
                        'parking_session_id': str(session.id),
                        'ended_by': 'officer',
                        'officer_name': officer.full_name
                    }
                )

                response_data['session_ended'] = True
                response_data['message'] = 'Session ended successfully'

            return Response(response_data, status=status.HTTP_200_OK)

        except ParkingSession.DoesNotExist:
            logger.warning("ParkingSession not found: %s", session_id)
            return Response({'error': 'Parking session not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as exc:
            logger.exception("Error processing QR scan for session %s: %s", session_id, str(exc))
            return Response({'error': 'internal_server_error', 'details': str(exc)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class OfficerActivityLogsAPIView(generics.ListAPIView):
    """Get officer's activity logs"""
    permission_classes = [IsAuthenticated]
    serializer_class = OfficerActionLogV2Serializer
    
    def get_queryset(self):
        return OfficerLog.objects.filter(officer=self.request.user).order_by('-created_at')

class OfficerQRScansAPIView(generics.ListAPIView):
    """Get officer's QR scan history"""
    permission_classes = [IsAuthenticated]
    serializer_class = QRCodeScanSerializer
    
    def get_queryset(self):
        return QRCodeScan.objects.filter(officer=self.request.user).order_by('-created_at')

from rest_framework.permissions import IsAdminUser

class AdminViolationListAPIView(generics.ListAPIView):
    """List all violations for admin view"""
    queryset = Violation.objects.all().order_by('-created_at')
    serializer_class = ViolationListSerializer
    permission_classes = [IsAdminUser]

class AdminOfficerStatusListAPIView(generics.ListAPIView):
    """List all officers and their current status"""
    queryset = OfficerStatus.objects.all().order_by('-updated_at')
    serializer_class = OfficerStatusSerializer
    permission_classes = [IsAdminUser]

class AdminGlobalOfficerLogListAPIView(generics.ListAPIView):
    """List all officer logs (global) for admin monitor"""
    queryset = OfficerLog.objects.all().order_by('-created_at')
    serializer_class = OfficerActionLogV2Serializer
    permission_classes = [IsAdminUser]


class AdminOfficerReassignAPIView(APIView):
    """Reassign an officer to a specific parking zone"""
    permission_classes = [IsAdminUser]

    @transaction.atomic
    def post(self, request, pk):
        from apps.parking.models import Zone
        from apps.accounts.models import User
        
        try:
            officer = User.objects.get(id=pk, role=UserRole.OFFICER)
            zone_id = request.data.get('zone_id')
            
            if not zone_id:
                # If zone_id is empty, unassign
                status_obj, created = OfficerStatus.objects.get_or_create(officer=officer)
                status_obj.current_zone = None
                status_obj.save()
                return Response({'message': 'Officer unassigned successfully'}, status=status.HTTP_200_OK)

            zone = Zone.objects.get(id=zone_id, is_active=True)
            status_obj, created = OfficerStatus.objects.get_or_create(officer=officer)
            status_obj.current_zone = zone
            status_obj.save()

            OfficerLog.objects.create(
                officer=officer,
                action='reassigned_by_admin',
                details={'new_zone': zone.name, 'zone_id': str(zone.id)}
            )

            return Response({
                'message': f'Officer assigned to {zone.name} successfully',
                'officer': officer.full_name,
                'zone': zone.name
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
