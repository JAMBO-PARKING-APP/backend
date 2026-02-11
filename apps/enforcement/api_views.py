from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Q
from .serializers import ZoneSerializer, VehicleDetailSerializer, ViolationSerializer, ParkingSlotSerializer, OfficerLogSerializer
from .models import Violation
from apps.parking.models import Zone, ParkingSession
from apps.accounts.models import Vehicle

class OfficerZoneListView(generics.ListAPIView):
    serializer_class = ZoneSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # For now, return all active zones. In production, filter by officer assignment
        return Zone.objects.filter(is_active=True)

class ZoneDetailView(generics.RetrieveAPIView):
    serializer_class = ZoneSerializer
    permission_classes = [IsAuthenticated]
    queryset = Zone.objects.filter(is_active=True)

class ZoneSlotsView(generics.ListAPIView):
    serializer_class = ParkingSlotSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        zone_id = self.kwargs['zone_id']
        return Zone.objects.get(id=zone_id).slots.all()

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_vehicle(request):
    plate = request.GET.get('plate', '').strip()
    if not plate:
        return Response({'error': 'License plate required'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        vehicle = Vehicle.objects.get(license_plate__iexact=plate)
        serializer = VehicleDetailSerializer(vehicle)
        return Response(serializer.data)
    except Vehicle.DoesNotExist:
        return Response({'error': 'Vehicle not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def zone_live_status(request, zone_id):
    from django.utils import timezone
    zone = get_object_or_404(Zone, id=zone_id)
    
    # Get active sessions
    active_sessions = ParkingSession.objects.filter(
        zone=zone, 
        status='active'
    ).select_related('vehicle', 'parking_slot')
    
    # Get zone stats
    total_slots = zone.slots.count() or 50
    occupied_slots = active_sessions.count()
    
    sessions_data = []
    now = timezone.now()
    for session in active_sessions:
        # Calculate remaining time
        remaining_seconds = (session.planned_end_time - now).total_seconds()
        remaining_seconds = max(0, remaining_seconds)
        remaining_minutes = int(remaining_seconds / 60)
        
        sessions_data.append({
            'id': str(session.id),
            'vehicle_plate': session.vehicle.license_plate,
            'slot_code': session.parking_slot.slot_code if session.parking_slot else None,
            'start_time': session.start_time.isoformat(),
            'planned_end_time': session.planned_end_time.isoformat(),
            'duration_minutes': session.duration_minutes,
            'remaining_minutes': remaining_minutes,
            'estimated_cost': float(session.estimated_cost)
        })
    
    return Response({
        'zone_id': str(zone.id),
        'zone_name': zone.name,
        'total_slots': total_slots,
        'occupied_slots': occupied_slots,
        'available_slots': total_slots - occupied_slots,
        'occupancy_rate': (occupied_slots * 100) // total_slots if total_slots > 0 else 0,
        'active_sessions': sessions_data
    })

class CreateViolationView(generics.CreateAPIView):
    serializer_class = ViolationSerializer
    permission_classes = [IsAuthenticated]
    
    def perform_create(self, serializer):
        serializer.save(officer=self.request.user)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def officer_stats(request):
    officer = request.user
    
    # Get officer's violations today
    from django.utils import timezone
    today = timezone.now().date()
    
    violations_today = Violation.objects.filter(
        officer=officer,
        created_at__date=today
    ).count()
    
    total_violations = Violation.objects.filter(officer=officer).count()
    
    # Get assigned zones (for now, all active zones)
    assigned_zones = Zone.objects.filter(is_active=True).count()
    
    return Response({
        'violations_today': violations_today,
        'total_violations': total_violations,
        'assigned_zones': assigned_zones,
        'officer_name': officer.full_name
    })

class LogOfficerActionAPIView(generics.CreateAPIView):
    serializer_class = OfficerLogSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(officer=self.request.user)