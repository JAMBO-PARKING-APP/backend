"""
User Location & Country Detection Views
Handles location tracking, country detection, and caching
"""
import logging
from django.utils import timezone
from django.core.cache import cache
from rest_framework import status, generics, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import User
from .serializers_v2 import UserProfileSerializer
from apps.parking.models import UserLocation
from apps.common.models import Country
from apps.common.serializers import CountrySerializer

logger = logging.getLogger(__name__)


class UserLocationAPIView(APIView):
    """
    Handle user location tracking and country detection
    Caches location data in Redis
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """
        Update user's current location
        POST /api/user/location/
        Body: {
            "latitude": 0.3476,
            "longitude": 32.5825,
            "accuracy": 10.0
        }
        """
        try:
            latitude = float(request.data.get('latitude', 0))
            longitude = float(request.data.get('longitude', 0))
            accuracy = float(request.data.get('accuracy', 0))

            if not (-90 <= latitude <= 90) or not (-180 <= longitude <= 180):
                return Response(
                    {'error': 'Invalid latitude or longitude'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            user = request.user
            
            # Store location in database
            location = UserLocation.objects.create(
                user=user,
                latitude=latitude,
                longitude=longitude,
                accuracy=accuracy,
                is_driver_app=True,
                timestamp=timezone.now()
            )

            # Cache location in Redis (TTL: 5 minutes)
            cache_key = f'user:{user.id}:location'
            cache.set(cache_key, {
                'latitude': latitude,
                'longitude': longitude,
                'accuracy': accuracy,
                'timestamp': timezone.now().isoformat(),
            }, timeout=300)

            logger.info(f"✅ Location updated for user {user.phone}: ({latitude}, {longitude})")

            return Response({
                'message': 'Location updated',
                'location': {
                    'latitude': latitude,
                    'longitude': longitude,
                    'accuracy': accuracy,
                }
            }, status=status.HTTP_200_OK)

        except (ValueError, TypeError) as e:
            logger.warning(f"Invalid location data: {e}")
            return Response(
                {'error': 'Invalid location data'},
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Error updating location: {e}")
            return Response(
                {'error': 'Failed to update location'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def get(self, request):
        """
        Get user's current location from cache
        GET /api/user/location/
        """
        user = request.user
        cache_key = f'user:{user.id}:location'
        
        cached_location = cache.get(cache_key)
        if cached_location:
            return Response(cached_location, status=status.HTTP_200_OK)
        
        # Fallback to last location from database
        try:
            last_location = UserLocation.objects.filter(
                user=user,
                is_driver_app=True
            ).latest('timestamp')
            
            return Response({
                'latitude': last_location.latitude,
                'longitude': last_location.longitude,
                'accuracy': last_location.accuracy,
                'timestamp': last_location.timestamp.isoformat(),
            }, status=status.HTTP_200_OK)
        except UserLocation.DoesNotExist:
            return Response(
                {'error': 'No location found'},
                status=status.HTTP_404_NOT_FOUND
            )


class CountryDetectionAPIView(APIView):
    """
    Detect or get user's country
    Handles auto-detection from coordinates or manual selection
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Get user's current country
        GET /api/user/country/
        """
        user = request.user
        
        if user.country:
            serializer = CountrySerializer(user.country)
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        return Response(
            {'error': 'Country not set'},
            status=status.HTTP_404_NOT_FOUND
        )

    def post(self, request):
        """
        Set or detect user's country
        POST /api/user/country/
        Body (option 1): {
            "latitude": 0.3476,
            "longitude": 32.5825
        }
        Body (option 2): {
            "country_id": "uuid"
        }
        """
        user = request.user

        # Option 1: Detect from coordinates
        if 'latitude' in request.data and 'longitude' in request.data:
            latitude = float(request.data.get('latitude'))
            longitude = float(request.data.get('longitude'))
            
            # Simple country detection (Uganda is ~0.4°N, 32.5°E)
            # In production, use a proper geocoding service like geopy
            detected_country = self._detect_country_from_coords(latitude, longitude)
            
            if detected_country:
                user.country = detected_country
                user.save()
                
                # Cache in Redis (TTL: 24 hours)
                cache_key = f'user:{user.id}:country'
                cache.set(cache_key, detected_country.id, timeout=86400)
                
                logger.info(f"✅ Country auto-detected for {user.phone}: {detected_country.name}")
                
                serializer = CountrySerializer(detected_country)
                return Response({
                    'message': 'Country detected',
                    'country': serializer.data,
                    'auto_detected': True
                }, status=status.HTTP_200_OK)
        
        # Option 2: Manual country selection
        elif 'country_id' in request.data:
            country_id = request.data.get('country_id')
            try:
                country = Country.objects.get(id=country_id, is_active=True)
                user.country = country
                user.save()
                
                cache_key = f'user:{user.id}:country'
                cache.set(cache_key, country.id, timeout=86400)
                
                logger.info(f"✅ Country manually set for {user.phone}: {country.name}")
                
                serializer = CountrySerializer(country)
                return Response({
                    'message': 'Country updated',
                    'country': serializer.data,
                    'auto_detected': False
                }, status=status.HTTP_200_OK)
            
            except Country.DoesNotExist:
                return Response(
                    {'error': 'Country not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
        
        return Response(
            {'error': 'Provide either coordinates or country_id'},
            status=status.HTTP_400_BAD_REQUEST
        )

    def _detect_country_from_coords(self, latitude, longitude):
        """
        Simple country detection based on coordinates
        In production, use geopy or a proper geocoding service
        """
        # Uganda: -1° to 4°N, 29° to 35°E
        if -1 <= latitude <= 4 and 29 <= longitude <= 35:
            return Country.objects.filter(iso_code='UG', is_active=True).first()
        
        # Kenya: -5° to 5°N, 33° to 42°E
        if -5 <= latitude <= 5 and 33 <= longitude <= 42:
            return Country.objects.filter(iso_code='KE', is_active=True).first()
        
        # Add more countries as needed
        
        return None


class UserReservationsAPIView(generics.ListAPIView):
    """
    Get user's reservations (bookings)
    GET /api/user/reservations/
    """
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        from apps.parking.models import Reservation
        return Reservation.objects.filter(
            user=self.request.user
        ).order_by('-created_at')
    
    def list(self, request, *args, **kwargs):
        from apps.parking.serializers import ReservationSerializer
        queryset = self.get_queryset()
        serializer = ReservationSerializer(queryset, many=True)
        
        return Response({
            'count': queryset.count(),
            'reservations': serializer.data
        }, status=status.HTTP_200_OK)


class ReservationDetailAPIView(APIView):
    """
    Get or cancel specific reservation
    GET /api/user/reservations/{id}/
    POST /api/user/reservations/{id}/cancel/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        """Get reservation details"""
        from apps.parking.models import Reservation
        from apps.parking.serializers import ReservationSerializer
        
        try:
            reservation = Reservation.objects.get(id=pk, user=request.user)
            serializer = ReservationSerializer(reservation)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Reservation.DoesNotExist:
            return Response(
                {'error': 'Reservation not found'},
                status=status.HTTP_404_NOT_FOUND
            )

    def post(self, request, pk):
        """Cancel reservation"""
        from apps.parking.models import Reservation
        
        action = request.data.get('action')
        if action != 'cancel':
            return Response(
                {'error': 'Invalid action'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            reservation = Reservation.objects.get(id=pk, user=request.user)
            
            if reservation.status == 'completed':
                return Response(
                    {'error': 'Cannot cancel completed reservation'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            if reservation.status == 'cancelled':
                return Response(
                    {'error': 'Reservation already cancelled'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            reservation.status = 'cancelled'
            reservation.save()
            
            logger.info(f"✅ Reservation {pk} cancelled by user {request.user.phone}")
            
            return Response({
                'message': 'Reservation cancelled',
                'reservation_id': str(pk)
            }, status=status.HTTP_200_OK)
        
        except Reservation.DoesNotExist:
            return Response(
                {'error': 'Reservation not found'},
                status=status.HTTP_404_NOT_FOUND
            )


class HostParkingDashboardAPIView(APIView):
    """
    Host/Owner dashboard
    GET /api/host/dashboard/
    Only accessible to users with role 'parking_owner' or 'host'
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Get host dashboard data"""
        user = request.user
        
        # Check if user is a host
        if user.role not in ['parking_owner', 'host']:
            return Response(
                {'error': 'User is not a parking host'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        from apps.parking.models import Zone, Reservation
        
        try:
            # Get user's zones
            zones = Zone.objects.filter(owner=user)
            
            # Calculate stats
            total_reservations = Reservation.objects.filter(
                zone__owner=user
            ).count()
            
            active_reservations = Reservation.objects.filter(
                zone__owner=user,
                status__in=['confirmed', 'active']
            ).count()
            
            # Revenue (from completed reservations)
            from django.db.models import Sum
            revenue = Reservation.objects.filter(
                zone__owner=user,
                status='completed'
            ).aggregate(total=Sum('price'))['total'] or 0
            
            return Response({
                'zones_count': zones.count(),
                'total_reservations': total_reservations,
                'active_reservations': active_reservations,
                'revenue': float(revenue),
                'zones': [
                    {
                        'id': str(zone.id),
                        'name': zone.name,
                        'capacity': zone.capacity,
                        'available_spots': zone.available_spots,
                        'hourly_rate': float(zone.hourly_rate),
                    }
                    for zone in zones
                ]
            }, status=status.HTTP_200_OK)
        
        except Exception as e:
            logger.error(f"Error fetching host dashboard: {e}")
            return Response(
                {'error': 'Failed to fetch dashboard'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class HostZoneSettingsAPIView(APIView):
    """
    Host parking zone settings and management
    GET/POST /api/host/zones/{id}/settings/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, zone_id):
        """Get zone settings"""
        from apps.parking.models import Zone
        
        try:
            zone = Zone.objects.get(id=zone_id, owner=request.user)
            
            return Response({
                'id': str(zone.id),
                'name': zone.name,
                'latitude': float(zone.latitude),
                'longitude': float(zone.longitude),
                'capacity': zone.capacity,
                'available_spots': zone.available_spots,
                'hourly_rate': float(zone.hourly_rate),
                'daily_rate': float(zone.daily_rate) if hasattr(zone, 'daily_rate') else None,
                'is_active': zone.is_active,
            }, status=status.HTTP_200_OK)
        
        except Zone.DoesNotExist:
            return Response(
                {'error': 'Zone not found or you do not have permission'},
                status=status.HTTP_404_NOT_FOUND
            )

    def post(self, request, zone_id):
        """Update zone settings"""
        from apps.parking.models import Zone
        
        try:
            zone = Zone.objects.get(id=zone_id, owner=request.user)
            
            # Update allowed fields
            if 'name' in request.data:
                zone.name = request.data['name']
            if 'hourly_rate' in request.data:
                zone.hourly_rate = float(request.data['hourly_rate'])
            if 'is_active' in request.data:
                zone.is_active = bool(request.data['is_active'])
            
            zone.save()
            
            logger.info(f"✅ Zone {zone_id} settings updated by host {request.user.phone}")
            
            return Response({
                'message': 'Zone settings updated',
                'zone_id': str(zone_id)
            }, status=status.HTTP_200_OK)
        
        except Zone.DoesNotExist:
            return Response(
                {'error': 'Zone not found'},
                status=status.HTTP_404_NOT_FOUND
            )
