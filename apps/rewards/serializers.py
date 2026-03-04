from rest_framework import serializers
from .models import LoyaltyAccount, PointTransaction

class LoyaltyAccountSerializer(serializers.ModelSerializer):
    class Meta:
        model = LoyaltyAccount
        fields = ['balance', 'lifetime_points', 'tier']

class PointTransactionSerializer(serializers.ModelSerializer):
    created_at = serializers.DateTimeField(format="%Y-%m-%d %H:%M")
    
    class Meta:
        model = PointTransaction
        fields = ['amount', 'transaction_type', 'description', 'reference_id', 'created_at']
