from django.contrib import admin
from django.utils.safestring import mark_safe

from .models import (
    Transaction,
    PaymentMethod,
    Refund,
    Invoice,
    WalletTransaction,
    PaymentGatewayConfig,
    PaymentGateway,
)


CREDENTIALS_HELP = {
    PaymentGateway.PESAPAL: mark_safe(
        '<p><strong>Pesapal v3</strong> (Uganda and regional):</p>'
        '<pre>{\n'
        '  "consumer_key": "your_consumer_key",\n'
        '  "consumer_secret": "your_consumer_secret",\n'
        '  "callback_url": "https://your-api.com/api/user/payments/pesapal/callback/"\n'
        '}</pre>'
        '<p>IPN URL is derived from <code>callback_url</code> (…/callback/ → …/ipn/). '
        'Save here — credentials apply immediately (auth cache is cleared).</p>'
    ),
    PaymentGateway.STRIPE: mark_safe(
        '<pre>{\n'
        '  "publishable_key": "pk_live_...",\n'
        '  "secret_key": "sk_live_...",\n'
        '  "webhook_secret": "whsec_..."\n'
        '}</pre>'
    ),
    PaymentGateway.MPESA: mark_safe(
        '<pre>{\n'
        '  "consumer_key": "...",\n'
        '  "consumer_secret": "...",\n'
        '  "shortcode": "174379",\n'
        '  "passkey": "..."\n'
        '}</pre>'
    ),
    PaymentGateway.FLUTTERWAVE: mark_safe(
        '<pre>{\n'
        '  "public_key": "FLWPUBK-...",\n'
        '  "secret_key": "FLWSECK-...",\n'
        '  "encryption_key": "..."\n'
        '}</pre>'
    ),
    PaymentGateway.PAYSTACK: mark_safe(
        '<pre>{\n'
        '  "public_key": "pk_live_...",\n'
        '  "secret_key": "sk_live_..."\n'
        '}</pre>'
    ),
    PaymentGateway.PAYPAL: mark_safe(
        '<pre>{\n'
        '  "client_id": "...",\n'
        '  "client_secret": "...",\n'
        '  "mode": "live"\n'
        '}</pre>'
    ),
    PaymentGateway.RAZORPAY: mark_safe(
        '<pre>{\n'
        '  "key_id": "rzp_live_...",\n'
        '  "key_secret": "..."\n'
        '}</pre>'
    ),
}


@admin.register(PaymentGatewayConfig)
class PaymentGatewayConfigAdmin(admin.ModelAdmin):
    list_display = (
        'gateway',
        'name',
        'country',
        'is_active',
        'is_sandbox',
        'priority',
        'credentials_status',
    )
    list_filter = ('gateway', 'country', 'is_active', 'is_sandbox')
    search_fields = ('name', 'gateway', 'country__name', 'country__iso_code')
    ordering = ('-priority', 'name')
    autocomplete_fields = ('country',)
    readonly_fields = ('created_at', 'updated_at', 'credentials_help_panel')

    fieldsets = (
        (
            None,
            {
                'fields': ('country', 'gateway', 'name', 'is_active', 'is_sandbox', 'priority'),
                'description': 'One row per (country, gateway). Higher priority is preferred when resolving.',
            },
        ),
        (
            'API credentials (JSON)',
            {
                'fields': ('credentials', 'credentials_help_panel'),
                'description': 'Secrets are stored in the database; restrict admin access appropriately.',
            },
        ),
        (
            'Timestamps',
            {'fields': ('created_at', 'updated_at'), 'classes': ('collapse',)},
        ),
    )

    def credentials_status(self, obj):
        creds = obj.credentials or {}
        if obj.gateway == PaymentGateway.PESAPAL:
            ok = bool(creds.get('consumer_key') and creds.get('consumer_secret'))
        elif obj.gateway == PaymentGateway.STRIPE:
            ok = bool(creds.get('secret_key') or creds.get('publishable_key'))
        elif obj.gateway in (PaymentGateway.PAYSTACK, PaymentGateway.FLUTTERWAVE):
            ok = bool(creds.get('secret_key') or creds.get('public_key'))
        else:
            ok = bool(creds)
        return 'Ready' if ok else 'Incomplete'

    credentials_status.short_description = 'Keys'

    def credentials_help_panel(self, obj):
        gw = getattr(obj, 'gateway', None) if obj else None
        if not gw:
            return mark_safe(
                '<p>Select <strong>Gateway</strong> and save once; reopen this row to see JSON templates.</p>'
            )
        return CREDENTIALS_HELP.get(gw, mark_safe('<p>Enter credentials as JSON.</p>'))

    credentials_help_panel.short_description = 'Reference'

    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        if 'credentials' in form.base_fields:
            form.base_fields['credentials'].help_text = (
                'JSON object. After save, Pesapal auth cache clears so new keys are used immediately.'
            )
        return form


@admin.register(PaymentMethod)
class PaymentMethodAdmin(admin.ModelAdmin):
    list_display = ('user', 'card_brand', 'card_last_four', 'is_default', 'is_active')
    list_filter = ('card_brand', 'is_default', 'is_active')
    search_fields = ('user__phone', 'card_last_four')
    autocomplete_fields = ['user']


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('user', 'amount', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('user__phone', 'idempotency_key')
    autocomplete_fields = ['user']
    readonly_fields = ('stripe_payment_intent_id', 'processor_response')


@admin.register(Refund)
class RefundAdmin(admin.ModelAdmin):
    list_display = ('original_transaction', 'amount', 'status', 'created_at')
    list_filter = ('status',)
    readonly_fields = ('stripe_refund_id',)


@admin.register(WalletTransaction)
class WalletTransactionAdmin(admin.ModelAdmin):
    list_display = ('user', 'transaction_type', 'amount', 'opening_balance', 'closing_balance', 'created_at', 'status')
    list_filter = ('transaction_type', 'status', 'created_at')
    search_fields = ('user__phone', 'description')
    autocomplete_fields = ['user']
    readonly_fields = ('opening_balance', 'closing_balance', 'created_at')


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ('invoice_number', 'transaction', 'created_at')
    search_fields = ('invoice_number',)
