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
        if not hasattr(request, 'user') or not request.user.is_authenticated:
            return None
        
        if request.path.startswith('/admin/') or not request.path.startswith('/api/'):
            return None
        
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        if not auth_header.startswith('Bearer '):
            return None
        
        token_str = auth_header.split(' ')[1]
        
        try:
            token = AccessToken(token_str)
            token_jti = str(token.get('jti', ''))
            
            user = User.objects.filter(id=request.user.id).first()
            if not user:
                return None
            
            if user.current_session_token and user.current_session_token != token_jti:
                return JsonResponse(
                    {
                        'detail': 'Your session has been invalidated. Please log in again.',
                        'code': 'session_invalidated'
                    },
                    status=401,
                    headers={'X-Session-Invalidated': 'true'}
                )
        
        except Exception as e:
            pass
        
        return None
