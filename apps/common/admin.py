import json
from datetime import timedelta
from django.contrib import admin
from django.urls import path
from django.http import HttpResponseForbidden, JsonResponse
from django.template.response import TemplateResponse
from django.core.cache import caches
from django_redis import get_redis_connection
from django.utils import timezone
from django.utils.html import format_html
from apps.payments.models import PaymentGatewayConfig
from .api_views import _get_system_usage
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
    actions = ['enable_all_countries', 'disable_all_countries']

    def enable_all_countries(self, request, queryset):
        Country.objects.update(is_active=True)
        self.message_user(request, "All countries have been enabled.")
    enable_all_countries.short_description = "Enable all countries"

    def disable_all_countries(self, request, queryset):
        Country.objects.update(is_active=False)
        self.message_user(request, "All countries have been disabled.")
    disable_all_countries.short_description = "Disable all countries"

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


def _build_region_request_stats():
    redis_client = get_redis_connection('default')
    country_totals = {}

    for raw_key in redis_client.scan_iter('monitor:requests:country:*:total'):
        key = raw_key.decode('utf-8')
        parts = key.split(':')
        if len(parts) < 6:
            continue
        country_code = parts[-2]
        count = int(redis_client.get(key) or 0)
        country_totals[country_code] = country_totals.get(country_code, 0) + count

    countries = Country.objects.filter(iso_code__in=country_totals.keys())
    country_map = {country.iso_code: country.name for country in countries}

    region_data = []
    for country_code, total in sorted(country_totals.items(), key=lambda item: item[1], reverse=True)[:10]:
        region_data.append({
            'country_code': country_code,
            'country_name': country_map.get(country_code, country_code),
            'request_count': total,
        })

    return region_data


def _build_detected_region_trends(top_regions):
    redis_client = get_redis_connection('default')
    now = timezone.now()
    hours = [now - timedelta(hours=i) for i in range(11, -1, -1)]
    labels = [hour.strftime('%H:%M') for hour in hours]
    series = []

    for region in top_regions:
        values = []
        country_code = region['country_code']
        for hour in hours:
            key = f"monitor:requests:country:{country_code}:{hour.strftime('%Y%m%d%H')}"
            values.append(int(redis_client.get(key) or 0))
        series.append({
            'country_code': country_code,
            'country_name': region['country_name'],
            'values': values,
        })

    return {
        'labels': labels,
        'series': series,
    }


def realtime_monitor_view(request):
    if not request.user.is_active or not request.user.is_staff:
        return HttpResponseForbidden('Permission denied')

    context = {
        'title': 'Realtime API Monitor',
        'api_monitor_url': '/api/admin/system/monitor/',
        'api_health_url': '/api/admin/system/health/',
    }

    return TemplateResponse(request, 'admin/realtime_monitor.html', context)


original_get_urls = admin.site.get_urls

def get_admin_urls():
    return [
        path('realtime-monitor/', admin.site.admin_view(realtime_monitor_view), name='realtime-monitor'),
    ] + original_get_urls()

admin.site.get_urls = get_admin_urls
