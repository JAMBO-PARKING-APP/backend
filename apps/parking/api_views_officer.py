from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from apps.common.constants import ParkingStatus, UserRole
from apps.parking.models import ParkingSession, Zone
from apps.parking.serializers_v2 import ParkingSessionDetailSerializer, ZoneSerializer


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_qr_code(request):
    """
    Verify QR code for parking session
    
    POST /api/officer/verify-qr/
    Body: {"session_id": "uuid"}
    """
    # Check if user is an officer
    if request.user.role != UserRole.OFFICER:
        return Response(
            {'error': 'Only officers can verify QR codes'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    session_id = request.data.get('session_id')
    
    if not session_id:
        return Response(
            {'error': 'session_id is required'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        session = ParkingSession.objects.select_related(
            'vehicle__user', 'zone', 'parking_slot'
        ).get(id=session_id)
        
        # Check if session is active
        is_valid = session.status == ParkingStatus.ACTIVE
        
        return Response({
            'valid': is_valid,
            'session': ParkingSessionDetailSerializer(session).data,
            'message': 'Valid parking session' if is_valid else 'Session is not active'
        })
        
    except ParkingSession.DoesNotExist:
        return Response({
            'valid': False,
            'message': 'Invalid session ID'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def officer_zones(request):
    """
    Get zones assigned to the authenticated officer
    
    GET /api/officer/zones/
    """
    # Check if user is an officer
    if request.user.role != UserRole.OFFICER:
        return Response(
            {'error': 'Only officers can access this endpoint'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    # Get assigned zones with stats
    zones = request.user.assigned_zones.filter(is_active=True).prefetch_related('slots')
    
    zones_data = []
    for zone in zones:
        # Get active sessions count in this zone
        active_sessions = ParkingSession.objects.filter(
            zone=zone,
            status=ParkingStatus.ACTIVE
        ).count()
        
        zone_data = ZoneSerializer(zone).data
        zone_data['active_sessions'] = active_sessions
        zones_data.append(zone_data)
    
    return Response({
        'zones': zones_data,
        'total_zones': len(zones_data)
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def officer_zone_sessions(request, zone_id):
    """
    Get all active sessions in a specific zone
    
    GET /api/officer/zones/{zone_id}/sessions/
    """
    # Check if user is an officer
    if request.user.role != UserRole.OFFICER:
        return Response(
            {'error': 'Only officers can access this endpoint'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    # Check if officer is assigned to this zone
    if not request.user.assigned_zones.filter(id=zone_id).exists():
        return Response(
            {'error': 'You are not assigned to this zone'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    try:
        zone = Zone.objects.get(id=zone_id, is_active=True)
        
        # Get active and expired sessions
        sessions = ParkingSession.objects.filter(
            zone=zone,
            status__in=[ParkingStatus.ACTIVE, ParkingStatus.EXPIRED]
        ).select_related('vehicle__user', 'parking_slot').order_by('-start_time')
        
        return Response({
            'zone': ZoneSerializer(zone).data,
            'sessions': ParkingSessionDetailSerializer(sessions, many=True).data,
            'total_sessions': sessions.count()
        })
        
    except Zone.DoesNotExist:
        return Response(
            {'error': 'Zone not found'},
            status=status.HTTP_404_NOT_FOUND
        )
