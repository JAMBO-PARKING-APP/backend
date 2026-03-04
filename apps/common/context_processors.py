from django.core.cache import cache
from .models import Country, get_current_country

def regional_settings(request):
    """Context processor that provides regional data to all templates."""
    countries = cache.get('available_countries')
    if not countries:
        countries = list(Country.objects.filter(is_active=True).values('id', 'name', 'iso_code', 'flag_emoji'))
        cache.set('available_countries', countries, 3600)  
    
    current_country = get_current_country()
    
    return {
        'current_country': current_country,
        'available_countries': countries,
        'selected_country_id': request.session.get('selected_country_id')
    }
