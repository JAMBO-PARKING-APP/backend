from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.common.models import BaseModel, RegionalModel
from apps.common.constants import TransactionStatus

class PaymentGateway(models.TextChoices):
    PESAPAL = 'pesapal', _('Pesapal')
    STRIPE = 'stripe', _('Stripe')
    CASH = 'cash', _('Cash')
    WALLET = 'wallet', _('Wallet')

class PaymentGatewayConfig(RegionalModel, BaseModel):
    """Configuration for payment gateways per country"""
    gateway = models.CharField(max_length=20, choices=PaymentGateway.choices)
    name = models.CharField(max_length=100, help_text="Display name for the app")
    credentials = models.JSONField(help_text="API keys, secrets, etc.")
    is_sandbox = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)
    priority = models.PositiveIntegerField(default=0, help_text="Higher priority shows first")

    class Meta:
        unique_together = ('country', 'gateway')
        ordering = ['-priority', 'name']

    def __str__(self):
        country_name = self.country.name if self.country else "Global"
        return f"{self.gateway.title()} - {country_name}"

class PaymentMethod(BaseModel):
    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='payment_methods')
    card_last_four = models.CharField(max_length=4)
    card_brand = models.CharField(max_length=20)  # visa, mastercard, etc.
    is_default = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    stripe_payment_method_id = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return f"{self.card_brand} ****{self.card_last_four}"

class Transaction(BaseModel):
    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='transactions')
    parking_session = models.ForeignKey('parking.ParkingSession', on_delete=models.CASCADE, 
                                       related_name='transactions', null=True, blank=True)
    reservation = models.ForeignKey('parking.Reservation', on_delete=models.CASCADE,
                                   related_name='transactions', null=True, blank=True)
    
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=20, choices=TransactionStatus.choices, default=TransactionStatus.PENDING)
    payment_method = models.ForeignKey(PaymentMethod, on_delete=models.SET_NULL, null=True)
    
    # External payment processor fields
    stripe_payment_intent_id = models.CharField(max_length=100, unique=True, null=True, blank=True)
    pesapal_order_tracking_id = models.CharField(max_length=100, unique=True, null=True, blank=True)
    pesapal_merchant_reference = models.CharField(max_length=100, unique=True, null=True, blank=True)
    processor_response = models.JSONField(default=dict, blank=True)
    
    # Idempotency
    idempotency_key = models.CharField(max_length=100, unique=True)

    class Meta:
        indexes = [
            models.Index(fields=['user_id', 'status', 'created_at']),
            models.Index(fields=['status', 'created_at']),
        ]

    def __str__(self):
        return f"{self.user.phone} - {self.amount} ({self.status})"

class Refund(BaseModel):
    original_transaction = models.ForeignKey(Transaction, on_delete=models.CASCADE, related_name='refunds')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    reason = models.CharField(max_length=200)
    status = models.CharField(max_length=20, choices=TransactionStatus.choices, default=TransactionStatus.PENDING)
    stripe_refund_id = models.CharField(max_length=100, unique=True, null=True, blank=True)

    def __str__(self):
        return f"Refund ${self.amount} for {self.original_transaction}"

class Invoice(BaseModel):
    transaction = models.OneToOneField(Transaction, on_delete=models.CASCADE, related_name='invoice')
    invoice_number = models.CharField(max_length=20, unique=True)
    pdf_file = models.FileField(upload_to='invoices/', null=True, blank=True)

    def __str__(self):
        return self.invoice_number

class WalletTransaction(BaseModel):
    TRANSACTION_TYPES = [
        ('topup', _('Top-up')),
        ('payment', _('Parking Payment')),
        ('fine_payment', _('Fine Payment')),
        ('refund', _('Refund')),
    ]
    
    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE, related_name='wallet_transactions')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    status = models.CharField(max_length=20, choices=TransactionStatus.choices, default=TransactionStatus.COMPLETED)
    description = models.CharField(max_length=255)
    
    # Optional references
    related_transaction = models.ForeignKey(Transaction, on_delete=models.SET_NULL, null=True, blank=True)
    parking_session = models.ForeignKey('parking.ParkingSession', on_delete=models.SET_NULL, null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=['user_id', 'transaction_type', 'created_at']),
            models.Index(fields=['status', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.phone} - {self.transaction_type} - {self.amount}"