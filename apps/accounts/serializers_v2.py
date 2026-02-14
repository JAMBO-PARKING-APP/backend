from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User, Vehicle, OTPCode
from apps.parking.models import ParkingSession, Zone, Reservation
from apps.enforcement.models import Violation
from apps.payments.models import Transaction, PaymentMethod

class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ['id', 'license_plate', 'make', 'model', 'color', 'is_active']
        read_only_fields = ['id']

class UserProfileSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='get_full_name', read_only=True)
    vehicles = VehicleSerializer(many=True, read_only=True)
    profile_photo = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'phone', 'email', 'first_name', 'last_name', 'full_name', 
                  'role', 'profile_photo', 'is_verified', 'created_at', 'vehicles', 'wallet_balance']
        read_only_fields = ['id', 'role', 'is_verified', 'created_at', 'wallet_balance']
    
    def get_profile_photo(self, obj):
        """Return absolute URL for profile photo"""
        if obj.profile_photo:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_photo.url)
            # Fallback: construct URL manually if no request context
            from django.conf import settings
            return f"{settings.SITE_URL}{obj.profile_photo.url}" if hasattr(settings, 'SITE_URL') else obj.profile_photo.url
        return None

class UpdateProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['email', 'first_name', 'last_name', 'profile_photo']

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    password_confirm = serializers.CharField(write_only=True, min_length=6)
    
    class Meta:
        model = User
        fields = ['phone', 'first_name', 'last_name', 'email', 'password', 'password_confirm']
    
    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({'password': 'Passwords do not match'})
        return data
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.role = 'driver'
        user.save()
        return user

class LoginSerializer(serializers.Serializer):
    phone = serializers.CharField()
    password = serializers.CharField(write_only=True)
    
    def validate(self, data):
        phone = data.get('phone')
        password = data.get('password')
        print(f"Login attempt for phone: {phone}")
        
        user = authenticate(username=phone, password=password)
        if not user:
            print(f"DEBUG: Authentication failed for: {phone}. Checking if user exists...")
            user_exists = User.objects.filter(phone=phone).exists()
            print(f"DEBUG: User exists: {user_exists}")
            if user_exists:
                u = User.objects.get(phone=phone)
                print(f"DEBUG: User is_active: {u.is_active}, is_verified: {u.is_verified}")
                if not u.is_active:
                    raise serializers.ValidationError({'detail': 'Account disabled'})
            raise serializers.ValidationError('Invalid phone or password')
        
        print(f"Authentication successful for: {phone}")
        data['user'] = user
        return data

class AddVehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ['license_plate', 'make', 'model', 'color']

class PaymentMethodSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentMethod
        fields = ['id', 'card_brand', 'card_last_four', 'is_default', 'is_active']
        read_only_fields = ['id']

class UserLocationSerializer(serializers.ModelSerializer):
    class Meta:
        from .models import UserLocation
        model = UserLocation
        fields = ['latitude', 'longitude', 'is_driver_app', 'timestamp']
        read_only_fields = ['timestamp']
    
    def to_internal_value(self, data):
        # Round coordinates to 6 decimal places to match model constraints
        if 'latitude' in data:
            try:
                data['latitude'] = round(float(data['latitude']), 6)
            except (ValueError, TypeError):
                pass
        if 'longitude' in data:
            try:
                data['longitude'] = round(float(data['longitude']), 6)
            except (ValueError, TypeError):
                pass
        return super().to_internal_value(data)
    
    def create(self, validated_data):
        from .models import UserLocation
        # Ensure we have the user from context if not passed
        user = validated_data.pop('user', None)
        if not user and 'view' in self.context:
            user = self.context['view'].request.user
        
        return UserLocation.objects.create(user=user, **validated_data)
