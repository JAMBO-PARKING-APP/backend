from datetime import timedelta
from django.utils import timezone
from django.db import transaction
from rest_framework import status, generics
from rest_framework.decorators import api_view
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from apps.common.constants import ParkingStatus, SlotStatus
from .models import Zone, ParkingSlot, ParkingSession, Reservation
from .serializers import ZoneSerializer, ParkingSessionSerializer, ReservationSerializer

class ZoneListView(generics.ListAPIView):
    queryset = Zone.objects.filter(is_active=True)
    serializer_class = ZoneSerializer
    permission_classes = [IsAuthenticated]

class ZoneAvailabilityView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, zone_id):
        try:
            zone = Zone.objects.get(id=zone_id, is_active=True)
            available_slots = zone.slots.filter(status=SlotStatus.AVAILABLE).count()
            total_slots = zone.slots.count()
            
            return Response({
                'zone': ZoneSerializer(zone).data,
                'available_slots': available_slots,
                'total_slots': total_slots,
                'occupancy_rate': (total_slots - available_slots) / total_slots if total_slots > 0 else 0
            })
        except Zone.DoesNotExist:
            return Response({'error': 'Zone not found'}, status=status.HTTP_404_NOT_FOUND)

class StartParkingView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        vehicle_id = request.data.get('vehicle_id')
        zone_id = request.data.get('zone_id')
        slot_id = request.data.get('slot_id')  # Optional
        duration_hours = request.data.get('duration_hours', 1)

        try:
            vehicle = request.user.vehicles.get(id=vehicle_id, is_active=True)
            zone = Zone.objects.get(id=zone_id, is_active=True)
            
            # Check for active session
            if ParkingSession.objects.filter(vehicle=vehicle, status=ParkingStatus.ACTIVE).exists():
                return Response({'error': 'Vehicle already has an active parking session'}, 
                              status=status.HTTP_400_BAD_REQUEST)
            
            # Handle slot selection
            parking_slot = None
            if slot_id:
                parking_slot = ParkingSlot.objects.get(id=slot_id, zone=zone, status=SlotStatus.AVAILABLE)
                parking_slot.status = SlotStatus.OCCUPIED
                parking_slot.save()
            
            # Create session
            planned_end = timezone.now() + timedelta(hours=duration_hours)
            estimated_cost = zone.hourly_rate * duration_hours
            
            session = ParkingSession.objects.create(
                vehicle=vehicle,
                zone=zone,
                parking_slot=parking_slot,
                planned_end_time=planned_end,
                estimated_cost=estimated_cost
            )
            
            return Response({
                'session': ParkingSessionSerializer(session).data,
                'message': 'Parking session started successfully'
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

class ExtendParkingView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        session_id = request.data.get('session_id')
        additional_hours = request.data.get('additional_hours', 1)

        try:
            session = ParkingSession.objects.get(
                id=session_id,
                vehicle__user=request.user,
                status=ParkingStatus.ACTIVE
            )
            
            session.planned_end_time += timedelta(hours=additional_hours)
            session.estimated_cost += session.zone.hourly_rate * additional_hours
            session.save()
            
            return Response({
                'session': ParkingSessionSerializer(session).data,
                'message': 'Parking session extended successfully'
            })
            
        except ParkingSession.DoesNotExist:
            return Response({'error': 'Active session not found'}, status=status.HTTP_404_NOT_FOUND)

class EndParkingView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        session_id = request.data.get('session_id')

        try:
            session = ParkingSession.objects.get(
                id=session_id,
                vehicle__user=request.user,
                status=ParkingStatus.ACTIVE
            )
            
            session.end_session()
            
            return Response({
                'session': ParkingSessionSerializer(session).data,
                'message': 'Parking session ended successfully'
            })
            
        except ParkingSession.DoesNotExist:
            return Response({'error': 'Active session not found'}, status=status.HTTP_404_NOT_FOUND)

class ActiveSessionView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            session = ParkingSession.objects.get(
                vehicle__user=request.user,
                status=ParkingStatus.ACTIVE
            )
            return Response(ParkingSessionSerializer(session).data)
        except ParkingSession.DoesNotExist:
            return Response({'message': 'No active session'}, status=status.HTTP_404_NOT_FOUND)

class ReservationListCreateView(generics.ListCreateAPIView):
    serializer_class = ReservationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Reservation.objects.filter(vehicle__user=self.request.user, is_active=True)