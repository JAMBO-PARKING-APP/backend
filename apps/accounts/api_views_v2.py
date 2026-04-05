"""
User App API Endpoints
- Profile management
- Vehicle management
- Authentication
"""

import random
import logging
import threading
from datetime import timedelta
from django.contrib.auth import authenticate
from django.utils import timezone
from django.db.models import Q
from django.core.mail import EmailMessage
from django.conf import settings

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

logger = logging.getLogger(__name__)

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
        logger.debug(f"Registration attempt with data: {request.data}")
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            try:
                user = serializer.save()
                user.is_verified = True
                refresh = RefreshToken.for_user(user)
                access_token = refresh.access_token
                token_jti = str(access_token.get('jti', ''))
                user.current_session_token = token_jti
                user.app_version = request.data.get('app_version', '')
                user.device_model = request.data.get('device_model', '')
                user.device_os = request.data.get('device_os', 'android')
                device_info = request.data.get('device_info', '')
                user.last_login_device = device_info or request.META.get('HTTP_USER_AGENT', '')[:255]
                user.save()
                
                logger.info(f"User {user.phone} registered and auto-verified. Immediate login granted.")
                
                return Response({
                    'access': str(access_token),
                    'refresh': str(refresh),
                    'user': UserProfileSerializer(user).data,
                    'message': 'Registration successful'
                }, status=status.HTTP_201_CREATED)
                
            except Exception as e:
                logger.error(f"User creation failed during registration: {str(e)}")
                return Response({'error': f"Account creation failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        logger.warning(f"Registration validation failed: {serializer.errors}")
        errors = serializer.errors
        error_msg = "Registration failed"
        if isinstance(errors, dict):
            first_error = next(iter(errors.values()))
            if isinstance(first_error, list):
                error_msg = first_error[0]
            else:
                error_msg = str(first_error)
                
        return Response({'error': error_msg, 'details': errors}, status=status.HTTP_400_BAD_REQUEST)

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
            user.app_version = request.data.get('app_version', '')
            user.device_model = request.data.get('device_model', '')
            user.device_os = request.data.get('device_os', 'android')
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
            user.app_version = request.data.get('app_version', '')
            user.device_model = request.data.get('device_model', '')
            user.device_os = request.data.get('device_os', 'android')
            user.last_login_device = device_info or request.META.get('HTTP_USER_AGENT', '')[:255]
            user.save()
            
            # Log what we're returning
            user_data = UserProfileSerializer(user).data
            logger.info(f"✅ Login successful for {user.phone}")
            logger.info(f"  JTI: {token_jti[:30]}...")
            logger.info(f"  User data fields: {list(user_data.keys())}")
            logger.info(f"  Has country_details: {'country_details' in user_data}")
            logger.debug(f"  Full response: {user_data}")
            
            return Response({
                'access': str(access_token),
                'refresh': str(refresh),
                'user': user_data,
                'message': 'Login successful'
            }, status=status.HTTP_200_OK)
        try:
            logger.warning(f"LoginAPIView: serializer.errors = {serializer.errors}")
        except Exception:
            logger.warning("LoginAPIView: could not log serializer.errors")
        errors = serializer.errors
        if isinstance(errors, dict) and errors.get('detail'):
            detail = errors.get('detail')
            message = detail[0] if isinstance(detail, (list, tuple)) else detail
            logger.warning(f"Login failed for {request.data.get('phone')}: {message}")
            return Response({'error': message}, status=status.HTTP_403_FORBIDDEN)

        logger.warning(f"Login validation failed: {errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ProfileAPIView(APIView):
    """Get and update user profile"""
    permission_classes = [IsAuthenticated]
    serializer_class = UserProfileSerializer

    @extend_schema(responses={200: UserProfileSerializer})
    
    def get(self, request):
        logger.info(f"Profile GET request from user {request.user.phone}")
        serializer = UserProfileSerializer(request.user, context={'request': request})
        logger.info(f"Profile returned for user {request.user.phone}")
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    def put(self, request):
        logger.info(f"Profile PUT request from user {request.user.phone}")
        serializer = UpdateProfileSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            logger.info(f"Profile updated for user {request.user.phone}")
            return Response({
                'message': 'Profile updated successfully',
                'user': UserProfileSerializer(request.user, context={'request': request}).data
            }, status=status.HTTP_200_OK)
        
        logger.warning(f"Profile update failed for user {request.user.phone}: {serializer.errors}")
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
                subject = "Space Park Verification Code"
                message = f"Your Space Park verification code is: {otp_code}\n\nThis code will expire in 10 minutes."
                html_content = f"""
                <!DOCTYPE html>
                <html>
                <body style="margin: 0; padding: 0; background-color: #f6f9fc; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
                    <table border="0" cellpadding="0" cellspacing="0" width="100%" style="padding: 20px 0;">
                        <tr>
                            <td align="center">
                                <table border="0" cellpadding="0" cellspacing="0" width="600" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
                                    <!-- Header with Logo -->
                                    <tr>
                                        <td align="center" style="padding: 40px 0 20px 0; background-color: #ffffff;">
                                            <img src="https://iili.io/q0vCDYl.png" alt="Space Park Logo" width="150" style="display: block; outline: none; border: none; text-decoration: none;">
                                        </td>
                                    </tr>
                                    <!-- Body -->
                                    <tr>
                                        <td style="padding: 20px 40px 40px 40px;">
                                            <h1 style="color: #1a1f36; font-size: 24px; font-weight: 600; margin: 0; text-align: center;">Verification Code</h1>
                                            <p style="color: #4f566b; font-size: 16px; line-height: 24px; margin-top: 20px; text-align: center;">
                                                You requested a new verification code. Please use the following code to continue with your Space Park session.
                                            </p>
                                            
                                            <div style="margin: 30px 0; padding: 25px; background-color: #f8fbff; border-radius: 8px; text-align: center;">
                                                <span style="font-family: monospace; font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #5469d4;">{otp_code}</span>
                                            </div>
                                            
                                            <p style="color: #697386; font-size: 14px; line-height: 20px; text-align: center;">
                                                This code is valid for <strong>10 minutes</strong>. For security, never share this code with anyone.
                                            </p>
                                        </td>
                                    </tr>
                                    <!-- Footer -->
                                    <tr>
                                        <td style="padding: 20px 40px; background-color: #f7fafc; text-align: center; border-top: 1px solid #e3e8ee;">
                                            <p style="color: #a3acb9; font-size: 12px; margin: 0;">&copy; 2026 Space Park Systems. All rights reserved.</p>
                                            <p style="color: #a3acb9; font-size: 12px; margin: 5px 0 0 0;">Did not request this? You can safely ignore this email.</p>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </table>
                </body>
                </html>
                """
                email = EmailMessage(
                    subject=subject,
                    body=message,
                    from_email=f"Space Park <{settings.DEFAULT_FROM_EMAIL}>",
                    to=[user.email],
                    bcc=[settings.DEFAULT_FROM_EMAIL],
                )
                email.content_subtype = "html"
                email.body = html_content
                email.send(fail_silently=False)
            except Exception as e:
                logger.error(f"Failed to resend OTP email to {user.email}: {str(e)}")
                return Response({
                    'error': 'Failed to send email. Please check your internet or try again later.',
                    'details': str(e)
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            return Response({
                'message': 'OTP resent successfully to your email.',
                'phone': str(user.phone),
                'email': user.email
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
        user.current_session_token = None
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
