from .models import set_current_country, get_current_country
from .utils import get_country_from_coords
import logging

logger = logging.getLogger(__name__)

class RegionalContextMiddleware:
    """Middleware to set the regional context (Country) for the current thread.
    
    This identifies the user's country from their profile and sets it in a 
    thread-safe way so that the RegionalManager can automatically filter queries.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        set_current_country(None)
        
        # 1. Check for GPS Location Overrides (Highest Priority)
        lat = request.headers.get('X-Latitude') or request.META.get('HTTP_X_LATITUDE')
        lon = request.headers.get('X-Longitude') or request.META.get('HTTP_X_LONGITUDE')
        
        if lat and lon:
            try:
                country = get_country_from_coords(lat, lon)
                if country:
                    set_current_country(country)
                    logger.debug(f"RegionalContext: Set country to {country.name} via GPS coords ({lat}, {lon})")
            except Exception as e:
                logger.error(f"RegionalContext: GPS resolution failed: {e}")

        # 2. Check for explicit header override (Fall back if GPS failed or missing)
        if not get_current_country():
            country_id = request.headers.get('X-Country-ID') or request.headers.get('X-Country-Code')
            if not country_id:
                country_id = request.META.get('HTTP_X_COUNTRY_ID') or request.META.get('HTTP_X_COUNTRY_CODE')

            if country_id:
                from .models import Country
                try:
                    if len(country_id) == 2:
                        country = Country.objects.get(iso_code=country_id.upper(), is_active=True)
                    else: 
                        country = Country.objects.get(id=country_id, is_active=True)
                    set_current_country(country)
                    logger.debug(f"RegionalContext: Set country to {country.name} via header {country_id}")
                except (Country.DoesNotExist, Exception) as e:
                    logger.warning(f"RegionalContext: Failed to set country via header {country_id}: {e}")
        
        if request.user.is_authenticated:
            if not get_current_country():
                session_country_id = request.session.get('selected_country_id')
                if session_country_id:
                    from .models import Country
                    try:
                        country = Country.objects.get(id=session_country_id)
                        set_current_country(country)
                    except Country.DoesNotExist:
                        pass
            
            if not get_current_country():
                country = getattr(request.user, 'country', None)
                if country:
                    set_current_country(country)
                    logger.debug(f"RegionalContext: Set country to {country.name} via user profile")
        
        response = self.get_response(request)
        
        set_current_country(None)
        
        return response
