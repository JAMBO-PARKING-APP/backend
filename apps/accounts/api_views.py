import random
from datetime import datetime, timedelta
from django.contrib.auth import authenticate
from django.utils import timezone
from rest_framework import status, generics
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User, Vehicle, OTPCode
from .serializers import UserSerializer, VehicleSerializer, RegisterSerializer

class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            
            # Generate OTP
            otp_code = str(random.randint(100000, 999999))
            OTPCode.objects.create(
                user=user,
                code=otp_code,
                expires_at=timezone.now() + timedelta(minutes=10)
            )
            
            # TODO: Send SMS with OTP
            
            return Response({
                'message': 'OTP sent to your phone',
                'user_id': user.id
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone_number = request.data.get('phone_number')
        otp = request.data.get('otp')
        device_id = request.data.get('device_id')  # Unique device identifier from app
        device_info = request.data.get('device_info', '')  # Device model/info for logging
        
        if not phone_number or not otp:
            return Response({
                'error': 'Phone number and OTP are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(phone=phone_number)
            otp_obj = OTPCode.objects.get(
                user=user,
                code=otp,
                is_used=False,
                expires_at__gt=timezone.now()
            )
            
            otp_obj.is_used = True
            otp_obj.save()
            
            user.is_verified = True
            
            # Generate new JWT token
            refresh = RefreshToken.for_user(user)
            access_token = refresh.access_token
            
            # Get token ID (jti) for session tracking
            token_jti = str(access_token.get('jti', ''))
            
            # Update user session tracking (invalidates previous session)
            if device_id:
                user.current_device_id = device_id
            user.current_session_token = token_jti
            user.last_login_device = device_info or request.META.get('HTTP_USER_AGENT', '')[:255]
            user.save()
            
            return Response({
                'access': str(access_token),
                'refresh': str(refresh),
                'user': UserSerializer(user).data,
                'session_info': {
                    'device_id': user.current_device_id,
                    'login_time': timezone.now().isoformat()
                }
            })
            
        except (User.DoesNotExist, OTPCode.DoesNotExist):
            return Response({
                'error': 'Invalid OTP or expired'
            }, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone_number = request.data.get('phone_number')
        
        if not phone_number:
            return Response({
                'error': 'Phone number is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(phone=phone_number)
            
            # Generate OTP
            otp_code = str(random.randint(100000, 999999))
            OTPCode.objects.create(
                user=user,
                code=otp_code,
                expires_at=timezone.now() + timedelta(minutes=10)
            )
            
            # TODO: Send SMS with OTP
            print(f"OTP for {phone_number}: {otp_code}")  # For development
            
            return Response({
                'message': 'OTP sent to your phone',
                'user_id': user.id
            })
            
        except User.DoesNotExist:
            return Response({
                'error': 'User not found. Please register first.'
            }, status=status.HTTP_404_NOT_FOUND)

class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user

class VehicleListCreateView(generics.ListCreateAPIView):
    serializer_class = VehicleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Vehicle.objects.filter(user=self.request.user, is_active=True)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)