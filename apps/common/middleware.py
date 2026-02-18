from .models import set_current_country

class RegionalContextMiddleware:
    """Middleware to set the regional context (Country) for the current thread.
    
    This identifies the user's country from their profile and sets it in a 
    thread-safe way so that the RegionalManager can automatically filter queries.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        set_current_country(None)
        
        if request.user.is_authenticated:
            session_country_id = request.session.get('selected_country_id')
            if request.user.is_superuser and session_country_id:
                from .models import Country
                try:
                    country = Country.objects.get(id=session_country_id)
                    set_current_country(country)
                except Country.DoesNotExist:
                    pass
            elif not request.user.is_superuser:
                country = getattr(request.user, 'country', None)
                if country:
                    set_current_country(country)
        
        response = self.get_response(request)
        
        set_current_country(None)
        
        return response
