"""
User App API Endpoints
- Profile management
- Vehicle management
- Authentication
"""

import random
from datetime import timedelta
from django.contrib.auth import authenticate
from django.utils import timezone
from django.db.models import Q

from rest_framework import status, generics, viewsets, serializers
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiExample

from .models import User, Vehicle, OTPCode
from .serializers_v2 import (
    UserProfileSerializer, UpdateProfileSerializer, RegisterSerializer,
    LoginSerializer, VehicleSerializer, AddVehicleSerializer,
    PaymentMethodSerializer, ResendOTPSerializer
)
from apps.payments.models import PaymentMethod

class RegisterAPIView(APIView):
    """User registration with phone number"""
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer

    @extend_schema(
        request=RegisterSerializer,
        responses={201: RegisterSerializer}, 
        examples=[OpenApiExample('Success', value={'message': 'Registration successful. OTP sent to your phone.', 'user_id': '...', 'phone': '...'})],
    )
    
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            otp_code = str(random.randint(100000, 999999))
            OTPCode.objects.create(
                user=user,
                code=otp_code,
                expires_at=timezone.now() + timedelta(minutes=10)
            )

            try:
                from apps.notifications.twilio_service import send_verification
                send_verification(to_phone=str(user.phone), channel='sms')
            except Exception:
                print(f"DEBUG: OTP for {user.phone}: {otp_code}")
            
            return Response({
                'message': 'Registration successful. OTP sent to your phone.',
                'user_id': user.id,
                'phone': str(user.phone)
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

from rest_framework_simplejwt.views import TokenRefreshView

class CustomTokenRefreshAPIView(TokenRefreshView):
    """
    Custom Token Refresh View that updates the user's current_session_token
    to avoid 401 session mismatch errors.
    """
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            access_token_str = response.data.get('access')
            if access_token_str:
                from rest_framework_simplejwt.tokens import AccessToken
                access_token = AccessToken(access_token_str)
                token_jti = str(access_token.get('jti', ''))
                
                # We need to find the user. Since refresh is unauthenticated, 
                # we can extract user_id from the new access token.
                user_id = access_token.get('user_id')
                if user_id:
                    User.objects.filter(id=user_id).update(current_session_token=token_jti)
        
        return response

class VerifyOTPAPIView(APIView):
    """Verify OTP and get JWT tokens - Single Device Login enforced"""
    permission_classes = [AllowAny]
    
    @extend_schema(
        request=serializers.Serializer, 
        responses={200: UserProfileSerializer},
    )
    
    def post(self, request):
        phone = request.data.get('phone')
        otp = request.data.get('otp')
        
        if not phone or not otp:
            return Response({
                'error': 'Phone and OTP are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(phone=phone) 
            otp_obj = OTPCode.objects.filter(
                user=user,
                code=otp,
                is_used=False,
                expires_at__gt=timezone.now()
            ).first()
            
            if not otp_obj:
                return Response({
                    'error': 'Invalid or expired OTP'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            otp_obj.is_used = True
            otp_obj.save()
            
            user.is_verified = True
            
            device_id = request.data.get('device_id')
            device_info = request.data.get('device_info', '')
            
            refresh = RefreshToken.for_user(user)
            access_token = refresh.access_token
            
            token_jti = str(access_token.get('jti', ''))
            
            if device_id:
                user.current_device_id = device_id
            user.current_session_token = token_jti
            user.last_login_device = device_info or request.META.get('HTTP_USER_AGENT', '')[:255]
            user.save()
            
            return Response({
                'access': str(access_token),
                'refresh': str(refresh),
                'user': UserProfileSerializer(user).data,
                'message': 'Login successful'
            }, status=status.HTTP_200_OK)
            
        except User.DoesNotExist:
            return Response({
                'error': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)

class LoginAPIView(APIView):
    """Direct login with phone and password - Single Device Login enforced"""
    permission_classes = [AllowAny]
    serializer_class = LoginSerializer

    @extend_schema(
        request=LoginSerializer,
        responses={200: UserProfileSerializer},
    )
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            
            if not user.is_verified:
                user.is_verified = True
            device_id = request.data.get('device_id')
            device_info = request.data.get('device_info', '')
            refresh = RefreshToken.for_user(user)
            access_token = refresh.access_token
            token_jti = str(access_token.get('jti', ''))
            if device_id:
                user.current_device_id = device_id
            user.current_session_token = token_jti
            user.last_login_device = device_info or request.META.get('HTTP_USER_AGENT', '')[:255]
            user.save()
            
            return Response({
                'access': str(access_token),
                'refresh': str(refresh),
                'user': UserProfileSerializer(user).data,
                'message': 'Login successful'
            }, status=status.HTTP_200_OK)
        try:
            print(f"LoginAPIView: serializer.errors = {serializer.errors}")
        except Exception:
            print("LoginAPIView: could not print serializer.errors")
        errors = serializer.errors
        if isinstance(errors, dict) and errors.get('detail'):
            detail = errors.get('detail')
            message = detail[0] if isinstance(detail, (list, tuple)) else detail
            return Response({'error': message}, status=status.HTTP_403_FORBIDDEN)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ProfileAPIView(APIView):
    """Get and update user profile"""
    permission_classes = [IsAuthenticated]
    serializer_class = UserProfileSerializer

    @extend_schema(responses={200: UserProfileSerializer})
    
    def get(self, request):
        serializer = UserProfileSerializer(request.user, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    def put(self, request):
        serializer = UpdateProfileSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({
                'message': 'Profile updated successfully',
                'user': UserProfileSerializer(request.user, context={'request': request}).data
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request):
        return self.put(request)

class VehicleListCreateAPIView(generics.ListCreateAPIView):
    """List user's vehicles and create new vehicle"""
    permission_classes = [IsAuthenticated]
    serializer_class = VehicleSerializer
    
    def get_queryset(self):
        return self.request.user.vehicles.filter(is_active=True).order_by('-created_at')
    
    def perform_create(self, serializer):
        license_plate = serializer.validated_data.get('license_plate')
        if Vehicle.objects.filter(license_plate=license_plate).exists():
            raise serializers.ValidationError({'license_plate': 'Vehicle with this license plate already exists'})
        
        serializer.save(user=self.request.user)

class VehicleDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """Get, update, or delete a specific vehicle"""
    permission_classes = [IsAuthenticated]
    serializer_class = VehicleSerializer
    
    def get_queryset(self):
        return self.request.user.vehicles.filter(is_active=True).order_by('-created_at')
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False
        instance.save()
        return Response({'message': 'Vehicle removed successfully'}, status=status.HTTP_204_NO_CONTENT)

class PaymentMethodListAPIView(generics.ListAPIView):
    """List user's payment methods"""
    permission_classes = [IsAuthenticated]
    serializer_class = PaymentMethodSerializer
    
    def get_queryset(self):
        return self.request.user.payment_methods.filter(is_active=True)

class SetDefaultPaymentMethodAPIView(APIView):
    """Set default payment method"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, pk):
        try:
            payment_method = request.user.payment_methods.get(id=pk, is_active=True)
            request.user.payment_methods.exclude(id=pk).update(is_default=False)
            payment_method.is_default = True
            payment_method.save()
            
            return Response({
                'message': 'Default payment method updated',
                'payment_method': PaymentMethodSerializer(payment_method).data
            }, status=status.HTTP_200_OK)
            
        except PaymentMethod.DoesNotExist:
            return Response({
                'error': 'Payment method not found'
            }, status=status.HTTP_404_NOT_FOUND)

class ResendOTPAPIView(APIView):
    """Resend OTP to phone number"""
    permission_classes = [AllowAny]
    serializer_class = ResendOTPSerializer

    @extend_schema(
        request=ResendOTPSerializer,
        responses={200: OpenApiExample('Success', value={'message': 'OTP resent successfully', 'phone': '...'})},
    )
    
    def post(self, request):
        phone = request.data.get('phone')
        
        if not phone:
            return Response({
                'error': 'Phone number is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(phone=phone)
            otp_code = str(random.randint(100000, 999999))
            OTPCode.objects.filter(user=user, is_used=False).update(is_used=True)
            OTPCode.objects.create(
                user=user,
                code=otp_code,
                expires_at=timezone.now() + timedelta(minutes=10)
            )
            try:
                from apps.notifications.twilio_service import send_verification
                send_verification(to_phone=str(user.phone), channel='sms')
            except Exception:
                print(f"DEBUG: OTP for {user.phone}: {otp_code}")
            
            return Response({
                'message': 'OTP resent successfully',
                'phone': str(user.phone)
            }, status=status.HTTP_200_OK)
            
        except User.DoesNotExist:
            return Response({
                'error': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)

class ChangePasswordAPIView(APIView):
    """Change user password"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        old_password = request.data.get('old_password')
        new_password = request.data.get('new_password')
        new_password_confirm = request.data.get('new_password_confirm')
        
        if not all([old_password, new_password, new_password_confirm]):
            return Response({
                'error': 'All fields are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not request.user.check_password(old_password):
            return Response({
                'error': 'Old password is incorrect'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if new_password != new_password_confirm:
            return Response({
                'error': 'New passwords do not match'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        request.user.set_password(new_password)
        request.user.save()
        
        return Response({
            'message': 'Password changed successfully'
        }, status=status.HTTP_200_OK)

class DeleteAccountAPIView(APIView):
    """Soft delete user account"""
    permission_classes = [IsAuthenticated]

    @extend_schema(
        responses={204: None},
        examples=[OpenApiExample('Success', value={'message': 'Account deletion requested successfully...'})],
    )

    def delete(self, request):
        user = request.user
        user.is_active = False
        user.deletion_requested_at = timezone.now()
        user.deletion_planned_at = timezone.now() + timedelta(days=30)
        user.save()
        
        return Response({
            'message': 'Account deletion requested successfully. Your account will be permanently deleted in 30 days.'
        }, status=status.HTTP_204_NO_CONTENT)

class UserLocationAPIView(generics.CreateAPIView):
    """Update user location"""
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        from .serializers_v2 import UserLocationSerializer
        return UserLocationSerializer
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

from rest_framework.permissions import IsAdminUser

class AdminUserListAPIView(generics.ListAPIView):
    """List all users for admin view"""
    queryset = User.objects.all().order_by('-created_at')
    serializer_class = UserProfileSerializer
    permission_classes = [IsAdminUser]
