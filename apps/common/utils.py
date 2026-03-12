import math
import json
import logging
from decimal import Decimal, ROUND_DOWN
from django.conf import settings
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
    lat1, lon1, lat2, lon2 = map(math.radians, [float(lat1), float(lon1), float(lat2), float(lon2)])

    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a)) 
    r = 6371000 
    return c * r

def get_country_from_coords(latitude, longitude):
    """
    Lookup country based on coordinates using global_countries.json.
    This is a local fallback for reverse geocoding.
    """
    try:
        data_path = settings.BASE_DIR / 'global_countries.json'
        with open(data_path, 'r', encoding='utf-8') as f:
            countries_data = json.load(f)
        
        closest_country = None
        min_distance = float('inf')
        
        for country in countries_data:
            if 'latlng' in country and len(country['latlng']) == 2:
                c_lat, c_lng = country['latlng']
                dist = calculate_distance(latitude, longitude, c_lat, c_lng)
                if dist < min_distance:
                    min_distance = dist
                    closest_country = country
        
        if closest_country and min_distance < 500000: 
            iso_code = closest_country.get('cca2')
            if iso_code:
                return Country.objects.filter(iso_code=iso_code, is_active=True).first()
                
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
    
    # Ensure dt is timezone-aware and in UTC
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
