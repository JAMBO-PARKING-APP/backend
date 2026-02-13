from rest_framework import serializers
from .models import Country

class CountrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Country
        fields = ('id', 'name', 'iso_code', 'currency', 'currency_symbol', 'timezone', 'phone_code', 'flag_emoji')
