"""
Middleware to enforce single device login by validating session tokens
"""
from django.utils.deprecation import MiddlewareMixin
from django.http import JsonResponse
from rest_framework_simplejwt.tokens import AccessToken
from apps.accounts.models import User


class SingleDeviceLoginMiddleware(MiddlewareMixin):
    """
    Validates that the request token matches the user's current session token.
    If not, returns 401 with session invalidated header.
    """
    
    def process_request(self, request):
        # Skip for non-authenticated requests
        if not hasattr(request, 'user') or not request.user.is_authenticated:
            return None
        
        # Skip for admin and non-API endpoints
        if request.path.startswith('/admin/') or not request.path.startswith('/api/'):
            return None
        
        # Get token from Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        if not auth_header.startswith('Bearer '):
            return None
        
        token_str = auth_header.split(' ')[1]
        
        try:
            # Decode token to get jti (token ID)
            token = AccessToken(token_str)
            token_jti = str(token.get('jti', ''))
            
            # Get user's current session token
            user = User.objects.filter(id=request.user.id).first()
            if not user:
                return None
            
            # Check if token matches current session
            if user.current_session_token and user.current_session_token != token_jti:
                # Session invalidated - user logged in from another device
                return JsonResponse(
                    {
                        'detail': 'Your session has been invalidated. Please log in again.',
                        'code': 'session_invalidated'
                    },
                    status=401,
                    headers={'X-Session-Invalidated': 'true'}
                )
        
        except Exception as e:
            # Token validation failed, let DRF handle it
            pass
        
        return None
