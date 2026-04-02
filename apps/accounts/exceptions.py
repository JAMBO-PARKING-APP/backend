from rest_framework.views import exception_handler
from rest_framework_simplejwt.exceptions import AuthenticationFailed


def custom_exception_handler(exc, context):
    """
    Custom exception handler that adds X-Session-Invalidated header
    when a session mismatch authentication error occurs.
    """
    response = exception_handler(exc, context)
    
    if response is not None and isinstance(exc, AuthenticationFailed):
        # Check if this is a session invalidation error
        # Try multiple ways to detect it
        is_session_invalidated = False
        
        # Method 1: Check exception code attribute
        if hasattr(exc, 'detail') and hasattr(exc.detail, 'code'):
            is_session_invalidated = exc.detail.code == 'session_invalidated'
        
        # Method 2: Check the detail message
        elif hasattr(exc, 'detail'):
            detail_str = str(exc.detail)
            is_session_invalidated = 'logged in on another device' in detail_str.lower()
        
        if is_session_invalidated:
            response['X-Session-Invalidated'] = 'true'
            if isinstance(response.data, dict):
                response.data['code'] = 'session_invalidated'
    
    return response
