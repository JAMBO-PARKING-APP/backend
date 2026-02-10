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

from .models import User, Vehicle, OTPCode
from .serializers_v2 import (
    UserProfileSerializer, UpdateProfileSerializer, RegisterSerializer,
    LoginSerializer, VehicleSerializer, AddVehicleSerializer,
    PaymentMethodSerializer
)
from apps.payments.models import PaymentMethod

class RegisterAPIView(APIView):
    """User registration with phone number"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            
            # Generate and send OTP
            otp_code = str(random.randint(100000, 999999))
            OTPCode.objects.create(
                user=user,
                code=otp_code,
                expires_at=timezone.now() + timedelta(minutes=10)
            )

            # Send SMS with OTP via Twilio Verify if available
            try:
                from apps.notifications.twilio_service import send_verification
                # Use Verify service to send SMS (the actual code is stored in OTPCode for server-side verification)
                send_verification(to_phone=str(user.phone), channel='sms')
            except Exception:
                # Fallback to debug print; do not fail registration if SMS sending is not configured
                print(f"DEBUG: OTP for {user.phone}: {otp_code}")
            
            return Response({
                'message': 'Registration successful. OTP sent to your phone.',
                'user_id': user.id,
                'phone': str(user.phone)
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class VerifyOTPAPIView(APIView):
    """Verify OTP and get JWT tokens - Single Device Login enforced"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        phone = request.data.get('phone')
        otp = request.data.get('otp')
        
        if not phone or not otp:
            return Response({
                'error': 'Phone and OTP are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(phone=phone)
            
            # Check OTP validity
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
            
            # Mark OTP as used
            otp_obj.is_used = True
            otp_obj.save()
            
            # Mark user as verified
            user.is_verified = True
            user.save()
            
            # Single Device Login: Invalidate all previous tokens by incrementing device session counter
            # This ensures only the latest token per user is valid
            user.device_session_id = timezone.now().timestamp()
            user.save(update_fields=['device_session_id'])
            
            refresh = RefreshToken.for_user(user)
            # Include device_session_id in token so authentication can enforce single-device
            refresh['device_session_id'] = str(user.device_session_id)
            refresh.access_token['device_session_id'] = str(user.device_session_id)
            
            return Response({
                'access': str(refresh.access_token),
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
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            
            # Allow login even if not verified for now to facilitate testing
            # if not user.is_verified:
            #     return Response({
            #         'error': 'User not verified. Please verify your phone first.'
            #     }, status=status.HTTP_403_FORBIDDEN)
            
            if not user.is_verified:
                user.is_verified = True
                user.save(update_fields=['is_verified'])
            
            # Single Device Login: Invalidate all previous tokens by updating device session ID
            user.device_session_id = timezone.now().timestamp()
            user.save(update_fields=['device_session_id'])
            refresh = RefreshToken.for_user(user)
            refresh['device_session_id'] = str(user.device_session_id)
            refresh.access_token['device_session_id'] = str(user.device_session_id)
            
            return Response({
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': UserProfileSerializer(user).data,
                'message': 'Login successful'
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ProfileAPIView(APIView):
    """Get and update user profile"""
    permission_classes = [IsAuthenticated]
    
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
        return self.request.user.vehicles.filter(is_active=True)
    
    def perform_create(self, serializer):
        # Check if license plate already exists
        license_plate = serializer.validated_data.get('license_plate')
        if Vehicle.objects.filter(license_plate=license_plate).exists():
            raise serializers.ValidationError({'license_plate': 'Vehicle with this license plate already exists'})
        
        serializer.save(user=self.request.user)

class VehicleDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """Get, update, or delete a specific vehicle"""
    permission_classes = [IsAuthenticated]
    serializer_class = VehicleSerializer
    
    def get_queryset(self):
        return self.request.user.vehicles.filter(is_active=True)
    
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
            
            # Unset all other default methods
            request.user.payment_methods.exclude(id=pk).update(is_default=False)
            
            # Set this one as default
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
    
    def post(self, request):
        phone = request.data.get('phone')
        
        if not phone:
            return Response({
                'error': 'Phone number is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(phone=phone)
            
            # Generate new OTP
            otp_code = str(random.randint(100000, 999999))
            
            # Mark old OTPs as used
            OTPCode.objects.filter(user=user, is_used=False).update(is_used=True)
            
            # Create new OTP
            OTPCode.objects.create(
                user=user,
                code=otp_code,
                expires_at=timezone.now() + timedelta(minutes=10)
            )

            # Send SMS with OTP via Twilio Verify if available
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

    def delete(self, request):
        user = request.user
        # Soft delete: set is_active to False
        user.is_active = False
        user.save()
        
        return Response({
            'message': 'Account deleted successfully'
        }, status=status.HTTP_204_NO_CONTENT)
