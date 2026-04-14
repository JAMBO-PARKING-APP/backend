import math
import json
import logging
from decimal import Decimal, ROUND_DOWN
from django.conf import settings
from django.core.cache import cache
from .models import Country

def truncate_coord(coord):
    """Truncate coordinate to 6 decimal places for DecimalField compatibility."""
    if coord is None:
        return None
    try:
        formatted = "{:.6f}".format(float(coord))
        return Decimal(formatted)
    except (ValueError, TypeError, Exception):
        return coord

logger = logging.getLogger(__name__)
def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees) using Haversine formula.
    Returns distance in meters.
    """
    try:
        lat1, lon1, lat2, lon2 = map(math.radians, [float(lat1), float(lon1), float(lat2), float(lon2)])
    except (TypeError, ValueError):
        return float('inf')

    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a)) 
    r = 6371000 
    return c * r

def get_country_from_coords(latitude, longitude):
    """
    Lookup country based on coordinates using the Country database table.
    Caches the results using Django cache for specific coordinate regions.
    Rounds lat/lon to 1 decimal place (~11km) to increase cache hit rate.
    """
    try:
        cache_lat = round(float(latitude), 1)
        cache_lon = round(float(longitude), 1)
        cache_key = f"geo_country_{cache_lat}_{cache_lon}"
        
        cached_id = cache.get(cache_key)
        if cached_id:
            if cached_id == 'none':
                return None
            return Country.objects.filter(id=cached_id, is_active=True).first()

        countries = Country.objects.filter(
            latitude__isnull=False, 
            longitude__isnull=False, 
            is_active=True
        ).only('id', 'iso_code', 'latitude', 'longitude')
        
        closest_country = None
        min_distance = float('inf')
        
        for country in countries:
            dist = calculate_distance(latitude, longitude, country.latitude, country.longitude)
            if dist < min_distance:
                min_distance = dist
                closest_country = country

        res_country = None
        if closest_country and min_distance < 500000: 
             res_country = closest_country
        
        if res_country:
            cache.set(cache_key, str(res_country.id), timeout=3600)
        else:
            cache.set(cache_key, 'none', timeout=1800)
            
        return res_country
                
    except Exception as e:
        logger.error(f"Error in get_country_from_coords: {str(e)}")
        
    return None
def get_user_local_time(user, dt):
    """
    Convert a datetime object (dt) to the user's local timezone.
    Falls back to settings.TIME_ZONE if user timezone cannot be determined.
    """
    import pytz
    from django.utils import timezone
    
    if timezone.is_naive(dt):
        dt = timezone.make_aware(dt, pytz.UTC)
    else:
        dt = dt.astimezone(pytz.UTC)
        
    user_tz_name = settings.TIME_ZONE
    
    if user and hasattr(user, 'country') and user.country:
        user_tz_name = user.country.timezone
        
    try:
        user_tz = pytz.timezone(user_tz_name)
        return dt.astimezone(user_tz)
    except Exception as e:
        logger.error(f"Error converting to user local time ({user_tz_name}): {str(e)}")
        return dt.astimezone(pytz.timezone(settings.TIME_ZONE))
