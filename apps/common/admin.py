from django.contrib import admin
from django.utils.html import format_html
from apps.payments.models import PaymentGatewayConfig
from .models import Country, SystemConfiguration, CountryConfig

class PaymentGatewayConfigInline(admin.TabularInline):
    """Link country ↔ gateway credentials (Pesapal, Stripe, …) from the Country admin."""
    model = PaymentGatewayConfig
    extra = 0
    fk_name = 'country'
    fields = ('gateway', 'name', 'is_active', 'is_sandbox', 'priority')
    show_change_link = True
    ordering = ('-priority', 'name')


@admin.register(Country)
class CountryAdmin(admin.ModelAdmin):
    list_display = ('name', 'iso_code', 'phone_code', 'currency', 'is_active')
    list_filter = ('is_active', 'currency')
    search_fields = ('name', 'iso_code', 'phone_code', 'currency')
    ordering = ('name',)
    list_editable = ('is_active',)
    inlines = (PaymentGatewayConfigInline,)

@admin.register(SystemConfiguration)
class SystemConfigurationAdmin(admin.ModelAdmin):
    list_display = ('company_name', 'min_android_version', 'min_ios_version', 'force_update', 'timezone')
    fieldsets = (
        ('General Settings', {'fields': ('company_name', 'currency', 'timezone')}),
        ('Contact Information', {'fields': ('contact_email', 'contact_phone')}),
        ('App Version Control', {'fields': ('min_android_version', 'min_ios_version', 'app_update_url', 'force_update')}),
    )


@admin.register(CountryConfig)
class CountryConfigAdmin(admin.ModelAdmin):
    list_display = (
        'country',
        'get_currency',
        'get_payment_methods',
        'exchange_rate_to_base',
        'is_active',
        'gateway_admin_link',
    )
    list_filter = ('is_active', 'country')
    search_fields = ('country__name', 'country__iso_code')
    autocomplete_fields = ['country']
    readonly_fields = ('created_at', 'updated_at', 'gateway_admin_link')
    
    fieldsets = (
        ('Country', {'fields': ('country',)}),
        (
            'Payment Configuration',
            {
                'fields': ('payment_methods', 'exchange_rate_to_base', 'is_active'),
                'description': (
                    'List which methods the app may offer (e.g. wallet, pesapal). '
                    'Actual API keys live under Country → Payment gateway configs.'
                ),
            },
        ),
        ('Gateway credentials', {'fields': ('gateway_admin_link',)}),
        ('Timestamps', {'fields': ('created_at', 'updated_at')}),
    )
    
    def get_currency(self, obj):
        return f"{obj.country.currency} ({obj.country.currency_symbol})"
    get_currency.short_description = 'Currency'
    
    def get_payment_methods(self, obj):
        return ', '.join(obj.payment_methods) if obj.payment_methods else 'None'
    get_payment_methods.short_description = 'Payment Methods'

    def gateway_admin_link(self, obj):
        if not obj or not obj.country_id:
            return '—'
        url = f'/admin/payments/paymentgatewayconfig/?country__id__exact={obj.country_id}'
        return format_html(
            '<a class="button" href="{}">Open gateway configs for {}</a>',
            url,
            obj.country.name,
        )

    gateway_admin_link.short_description = 'Gateway API keys'
