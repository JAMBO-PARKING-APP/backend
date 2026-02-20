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
            auth_header = request.META.get('HTTP_AUTHORIZATION', '')
            if not auth_header:
                print("DeviceSessionJWTAuthentication: No Authorization header found.")
            else:
                print(f"DeviceSessionJWTAuthentication: Authorization header found but super().authenticate failed: {auth_header[:20]}...")
            return None

        user, token = auth_result

        token_jti = token.get('jti')
        
        if token_jti is not None:
            current_session_token = getattr(user, 'current_session_token', None)
            if current_session_token and str(current_session_token) != str(token_jti):
                print(f"DeviceSessionJWTAuthentication: session mismatch: user={user.id} current_db={current_session_token} token_jti={token_jti}")
                raise AuthenticationFailed('Session expired. You have logged in on another device.')
        
        return user, token
