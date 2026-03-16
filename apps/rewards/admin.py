from django.contrib import admin
from .models import LoyaltyAccount, PointTransaction

@admin.register(LoyaltyAccount)
class LoyaltyAccountAdmin(admin.ModelAdmin):
    list_display = ('user', 'balance', 'tier', 'updated_at')
    list_filter = ('tier',)
    search_fields = ('user__phone', 'user__first_name', 'user__last_name')
    autocomplete_fields = ['user']
    readonly_fields = ('updated_at',)

@admin.register(PointTransaction)
class PointTransactionAdmin(admin.ModelAdmin):
    list_display = ('account', 'amount', 'transaction_type', 'created_at')
    list_filter = ('transaction_type',)
    search_fields = ('account__user__phone', 'description')
    autocomplete_fields = ['account']
    readonly_fields = ('created_at',)
