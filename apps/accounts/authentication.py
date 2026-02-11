from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import AuthenticationFailed


class DeviceSessionJWTAuthentication(JWTAuthentication):
    """Extends SimpleJWT authentication to enforce single-device login.

    Requires that tokens include a `device_session_id` claim which must match
    the current `device_session_id` on the `User` record.
    """

    def authenticate(self, request):
        # Debug: show incoming Authorization header
        try:
            auth_header = request.META.get('HTTP_AUTHORIZATION', None)
            print(f"DeviceSessionJWTAuthentication: Authorization header present: {bool(auth_header)} | header={auth_header}")
        except Exception:
            print("DeviceSessionJWTAuthentication: could not read Authorization header")

        auth_result = super().authenticate(request)
        if auth_result is None:
            print("DeviceSessionJWTAuthentication: super().authenticate returned None (no credentials or invalid token)")
            return None

        user, token = auth_result

        # Check if token has device_session_id claim
        token_device_session = token.payload.get('device_session_id')
        print(f"DeviceSessionJWTAuthentication: token payload keys: {list(token.payload.keys())}")
        
        if token_device_session is not None:
            # Get current session ID from user
            current_session_id = getattr(user, 'device_session_id', None)
            
            # If user has a session ID, compare it with token's session ID
            # Use string comparison to avoid float precision issues
            if str(current_session_id) != str(token_device_session):
                print(f"DeviceSessionJWTAuthentication: session mismatch: user={user.id} current={current_session_id} token={token_device_session}")
                raise AuthenticationFailed('Session expired. You have logged in on another device.')
        
        return user, token
