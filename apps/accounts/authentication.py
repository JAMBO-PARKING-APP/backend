from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import AuthenticationFailed


class DeviceSessionJWTAuthentication(JWTAuthentication):
    """Extends SimpleJWT authentication to enforce single-device login.

    Requires that tokens include a `device_session_id` claim which must match
    the current `device_session_id` on the `User` record.
    """

    def authenticate(self, request):
        auth_result = super().authenticate(request)
        if auth_result is None:
            return None

        user, token = auth_result

        # Check if token has device_session_id claim
        token_device_session = token.payload.get('device_session_id')
        
        if token_device_session is not None:
            # Get current session ID from user
            current_session_id = getattr(user, 'device_session_id', None)
            
            # If user has a session ID, compare it with token's session ID
            # Use string comparison to avoid float precision issues
            if str(current_session_id) != str(token_device_session):
                raise AuthenticationFailed('Session expired. You have logged in on another device.')
        
        return user, token
