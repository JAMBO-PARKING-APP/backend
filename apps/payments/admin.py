from django.contrib import admin
from .models import PaymentMethod, Transaction, Refund, Invoice

@admin.register(PaymentMethod)
class PaymentMethodAdmin(admin.ModelAdmin):
    list_display = ('user', 'card_brand', 'card_last_four', 'is_default', 'is_active')
    list_filter = ('card_brand', 'is_default', 'is_active')
    search_fields = ('user__phone', 'card_last_four')

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('user', 'amount', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('user__phone', 'idempotency_key')
    readonly_fields = ('stripe_payment_intent_id', 'processor_response')

@admin.register(Refund)
class RefundAdmin(admin.ModelAdmin):
    list_display = ('original_transaction', 'amount', 'status', 'created_at')
    list_filter = ('status',)
    readonly_fields = ('stripe_refund_id',)

@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ('invoice_number', 'transaction', 'created_at')
    search_fields = ('invoice_number',)