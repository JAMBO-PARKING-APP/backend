from rest_framework import serializers
from .models import Country, SystemConfiguration

class CountrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Country
        fields = ('id', 'name', 'iso_code', 'currency', 'currency_symbol', 'timezone', 'phone_code', 'flag_emoji', 'payment_methods', 'exchange_rate_to_base', 'is_active')

class SystemConfigurationSerializer(serializers.ModelSerializer):
    class Meta:
        model = SystemConfiguration
        fields = '__all__'
