from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)

class HardwareGetAccessTokenView(APIView):
    """
    Mock endpoint for hardware webclients (e.g. ANPR cameras).
    Returns a valid dummy JWT-like JSON payload.
    """
    authentication_classes = [] 
    permission_classes = []

    def post(self, request, *args, **kwargs):
        # We accept any payload and return a standard token
        logger.info(f"Hardware requesting access token. Payload: {request.data}")
        return Response({
            "access_token": "hardware_terminal_dummy_token_99348",
            "token_type": "bearer",
            "expires_in": 315360000, # 10 years
            "refresh_token": "hardware_terminal_dummy_refresh",
        }, status=status.HTTP_200_OK)
    
    def get(self, request, *args, **kwargs):
        return self.post(request, *args, **kwargs)
