from .models import set_current_country

class RegionalContextMiddleware:
    """Middleware to set the regional context (Country) for the current thread.
    
    This identifies the user's country from their profile and sets it in a 
    thread-safe way so that the RegionalManager can automatically filter queries.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Default to None
        set_current_country(None)
        
        # On request, identify user's country if authenticated
        if request.user.is_authenticated:
            # Superusers should see everything, so don't set a restriction context
            if not request.user.is_superuser:
                country = getattr(request.user, 'country', None)
                if country:
                    set_current_country(country)
        
        response = self.get_response(request)
        
        # Clean up after request to prevent leaks between threads
        set_current_country(None)
        
        return response
