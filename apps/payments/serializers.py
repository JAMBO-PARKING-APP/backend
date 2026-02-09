from rest_framework import serializers
from .models import PaymentMethod, Transaction, Refund

class PaymentMethodSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentMethod
        fields = ('id', 'card_brand', 'card_last_four', 'is_default')

class TransactionSerializer(serializers.ModelSerializer):
    session_info = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = ('id', 'amount', 'status', 'created_at', 'session_info')

    def get_session_info(self, obj):
        if obj.parking_session:
            return {
                'type': 'parking',
                'zone': obj.parking_session.zone.name,
                'vehicle': obj.parking_session.vehicle.license_plate
            }
        elif obj.reservation:
            return {
                'type': 'reservation',
                'zone': obj.reservation.zone.name,
                'vehicle': obj.reservation.vehicle.license_plate
            }
        return None

class RefundSerializer(serializers.ModelSerializer):
    class Meta:
        model = Refund
        fields = ('id', 'amount', 'reason', 'status', 'created_at')