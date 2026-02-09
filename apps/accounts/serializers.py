from rest_framework import serializers
from .models import User, Vehicle

class UserSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source='phone', read_only=True)
    
    class Meta:
        model = User
        fields = ('id', 'phone', 'phone_number', 'email', 'first_name', 'last_name', 'role', 'full_name')
        read_only_fields = ('id', 'role', 'phone_number')

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('phone', 'email', 'first_name', 'last_name', 'password', 'password_confirm')

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, **validated_data)
        return user

class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ('id', 'license_plate', 'make', 'model', 'color', 'is_active')
        read_only_fields = ('id',)