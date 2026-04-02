from rest_framework.views import exception_handler
from rest_framework_simplejwt.exceptions import AuthenticationFailed


def custom_exception_handler(exc, context):
    """
    Custom exception handler that adds X-Session-Invalidated header
    when a session mismatch authentication error occurs.
    """
    response = exception_handler(exc, context)
    
    if response is not None and isinstance(exc, AuthenticationFailed):
        # Check if this is a session invalidation error by checking the error code
        error_code = getattr(exc, 'get_codes', lambda: None)()
        if error_code == 'session_invalidated':
            response['X-Session-Invalidated'] = 'true'
            response.data['code'] = 'session_invalidated'
    
    return response
