from rest_framework import serializers
from .models import Transaction, PaymentMethod, Refund, Invoice, WalletTransaction

class PaymentMethodSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentMethod
        fields = ['id', 'card_brand', 'card_last_four', 'is_default', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']

class TransactionSerializer(serializers.ModelSerializer):
    payment_method_display = serializers.CharField(source='payment_method', read_only=True)
    user_phone = serializers.CharField(source='user.phone', read_only=True)
    
    class Meta:
        model = Transaction
        fields = ['id', 'user_phone', 'amount', 'status', 'payment_method_display',
                  'created_at', 'parking_session', 'reservation', 'pesapal_order_tracking_id']
        read_only_fields = ['id', 'status', 'created_at']

class WalletTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletTransaction
        fields = ['id', 'amount', 'transaction_type', 'status', 'description', 'created_at']
        read_only_fields = ['id', 'created_at']

class RefundSerializer(serializers.ModelSerializer):
    class Meta:
        model = Refund
        fields = ['id', 'amount', 'reason', 'status', 'created_at']
        read_only_fields = ['id', 'status', 'created_at']

class InvoiceSerializer(serializers.ModelSerializer):
    transaction_amount = serializers.DecimalField(source='transaction.amount', max_digits=12, decimal_places=2, read_only=True)
    transaction_status = serializers.CharField(source='transaction.status', read_only=True)
    
    class Meta:
        model = Invoice
        fields = ['id', 'invoice_number', 'transaction_amount', 'transaction_status', 
                  'pdf_file', 'created_at']
        read_only_fields = ['id', 'created_at']

class CreateTransactionSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    payment_method_id = serializers.UUIDField()
    parking_session_id = serializers.UUIDField(required=False, allow_null=True)
    violation_id = serializers.UUIDField(required=False, allow_null=True)
    idempotency_key = serializers.CharField(max_length=100)

class TransactionListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ['id', 'amount', 'status', 'created_at']
        read_only_fields = ['id', 'created_at']

class PesapalPaymentSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    description = serializers.CharField(max_length=100)
    parking_session_id = serializers.UUIDField(required=False, allow_null=True)
    reservation_id = serializers.UUIDField(required=False, allow_null=True)
    violation_id = serializers.UUIDField(required=False, allow_null=True)
    is_wallet_topup = serializers.BooleanField(required=False, default=False)
