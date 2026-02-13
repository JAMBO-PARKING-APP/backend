from rest_framework import serializers
from apps.common.serializers import CountrySerializer
from .models import User, Vehicle

class UserSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source='phone', read_only=True)
    country_details = CountrySerializer(source='country', read_only=True)
    
    class Meta:
        model = User
        fields = ('id', 'phone', 'phone_number', 'email', 'first_name', 'last_name', 'role', 'full_name', 'country_details')
        read_only_fields = ('id', 'role', 'phone_number', 'country_details')

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

    def validate_phone(self, value):
        from apps.common.models import Country
        import phonenumbers
        from phonenumbers import geocoder

        # Parse phone to detect country
        try:
            parsed = phonenumbers.parse(str(value), None)
            if not phonenumbers.is_valid_number(parsed):
                raise serializers.ValidationError("Invalid phone number")
            
            region_code = phonenumbers.region_code_for_number(parsed)
            if region_code:
                # Check if country exists and is active
                country = Country.objects.filter(iso_code=region_code, is_active=True).first()
                if not country:
                    raise serializers.ValidationError("Jambo Park is not currently available in your region.")
            else:
                raise serializers.ValidationError("Could not detect country from phone number")
                
        except Exception as e:
            if isinstance(e, serializers.ValidationError):
                raise e
            raise serializers.ValidationError("Invalid phone number format")
            
        return value

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