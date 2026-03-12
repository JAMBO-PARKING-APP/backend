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
    if request.user.role != UserRole.OFFICER:
        return Response(
            {'error': 'Only officers can access this endpoint'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    from django.db.models import Count, Q
    zones = request.user.assigned_zones.filter(is_active=True).annotate(
        active_session_count=Count(
            'sessions',
            filter=Q(sessions__status=ParkingStatus.ACTIVE)
        )
    )
    
    zones_data = []
    for zone in zones:
        zone_data = ZoneSerializer(zone).data
        zone_data['active_sessions'] = zone.active_session_count
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
    if request.user.role != UserRole.OFFICER:
        return Response(
            {'error': 'Only officers can access this endpoint'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    if not request.user.assigned_zones.filter(id=zone_id).exists():
        return Response(
            {'error': 'You are not assigned to this zone'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    try:
        zone = Zone.objects.get(id=zone_id, is_active=True)
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
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def overdue_users(request, zone_id):
    """
    Get users who are still in the zone radius but have no active session
    (sessions that are expired or recently completed)
    
    GET /api/officer/zones/{zone_id}/overdue-users/
    """
    if request.user.role != UserRole.OFFICER:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_403_FORBIDDEN)
        
    try:
        zone = Zone.objects.get(id=zone_id, is_active=True)
        from django.utils import timezone
        from datetime import timedelta
        cutoff = timezone.now() - timedelta(hours=2)
        
        overdue_sessions = ParkingSession.objects.filter(
            zone=zone,
            status__in=[ParkingStatus.EXPIRED, ParkingStatus.COMPLETED],
            updated_at__gte=cutoff
        ).select_related('vehicle__user')
        
        from apps.accounts.models import UserLocation
        from apps.common.utils import calculate_distance
        
        overdue_data = []
        for session in overdue_sessions:
            user = session.vehicle.user
            last_location = UserLocation.objects.filter(user=user).order_by('-timestamp').first()
            
            if last_location:
                distance = calculate_distance(
                    last_location.latitude, last_location.longitude,
                    zone.latitude, zone.longitude
                )
                
                if distance <= (zone.radius_meters + 20):
                    overdue_data.append({
                        'session_id': str(session.id),
                        'vehicle_plate': session.vehicle.license_plate,
                        'driver_name': f"{user.first_name} {user.last_name}",
                        'driver_phone': user.phone,
                        'status': session.status,
                        'distance_meters': int(distance),
                        'last_seen': last_location.timestamp.isoformat()
                    })
        
        return Response({
            'zone_name': zone.name,
            'overdue_users': overdue_data,
            'count': len(overdue_data)
        })
        
    except Zone.DoesNotExist:
        return Response({'error': 'Zone not found'}, status=404)
