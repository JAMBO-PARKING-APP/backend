from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import AuthenticationFailed
import logging

logger = logging.getLogger(__name__)


class DeviceSessionJWTAuthentication(JWTAuthentication):
    """Extends SimpleJWT authentication to enforce single-device login.

    Validates that the JWT's jti claim matches the user's current_session_token
    stored in the database. If not, the session is considered invalidated
    (user logged in on another device).
    """

    def authenticate(self, request):
        auth_result = super().authenticate(request)
        if auth_result is None:
            logger.debug(f"No JWT token found in request to {request.path}")
            return None

        user, token = auth_result
        logger.debug(f"AUTH CHECK for {user.phone} on {request.path}")
        token_jti = token.get('jti')
        current_session_token = getattr(user, 'current_session_token', None)
        logger.debug(f"  Token JTI: {str(token_jti)[:30]}...")
        logger.debug(f"  DB Session: {str(current_session_token)[:30] if current_session_token else 'NULL'}...")
        
        if token_jti is not None:
            # If both exist, they must match - otherwise the user logged in from another device
            if current_session_token:
                if str(current_session_token) != str(token_jti):
                    logger.warning(
                        f"SESSION MISMATCH for {user.phone} (ID: {user.id}). "
                        f"Token: {str(token_jti)[:30]}... vs DB: {str(current_session_token)[:30]}... "
                        f"Path: {request.path}"
                    )
                    raise AuthenticationFailed(
                        'Session expired. You have logged in on another device.',
                        code='session_invalidated'
                    )
                else:
                    logger.debug(f"Session match for {user.phone}")
            else:
                logger.debug(f"No session token in DB for {user.phone}, allowing request")
        
        return user, token
