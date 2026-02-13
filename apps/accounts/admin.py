from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from apps.common.admin_mixins import RegionalAdminMixin
from .models import User, Vehicle, OTPCode

@admin.register(User)
class UserAdmin(RegionalAdminMixin, BaseUserAdmin):
    list_display = ('phone', 'first_name', 'last_name', 'role', 'country', 'wallet_balance', 'is_active')
    list_filter = ('country', 'role', 'is_active', 'is_verified')
    search_fields = ('phone', 'first_name', 'last_name', 'email')
    ordering = ('-created_at',)
    actions = ['top_up_wallet']
    
    fieldsets = (
        (None, {'fields': ('phone', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'email', 'country', 'profile_photo')}),
        ('Wallet', {'fields': ('wallet_balance',)}),
        ('Permissions', {'fields': ('role', 'is_active', 'is_staff', 'is_superuser', 'is_verified')}),
        ('Officer Assignments', {'fields': ('assigned_zones',)}),
    )
    
    filter_horizontal = ('assigned_zones', 'groups', 'user_permissions')
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone', 'first_name', 'last_name', 'password1', 'password2', 'role'),
        }),
    )
    
    def top_up_wallet(self, request, queryset):
        from django.contrib import messages
        from decimal import Decimal
        
        # Simple top-up of 10000 UGX for selected users
        amount = Decimal('10000.00')
        count = 0
        
        for user in queryset:
            user.wallet_balance += amount
            user.save()
            count += 1
            
            # Log the transaction
            from apps.payments.models import WalletTransaction
            WalletTransaction.objects.create(
                user=user,
                amount=amount,
                transaction_type='topup',
                status='completed',
                description=f'Admin top-up by {request.user.phone}'
            )
        
        self.message_user(
            request,
            f'Successfully topped up {count} user(s) with UGX {amount}',
            messages.SUCCESS
        )
    
    top_up_wallet.short_description = 'Top up wallet (UGX 10,000)'

@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ('license_plate', 'user', 'make', 'model', 'is_active')
    list_filter = ('is_active', 'make')
    search_fields = ('license_plate', 'user__phone')

@admin.register(OTPCode)
class OTPCodeAdmin(admin.ModelAdmin):
    list_display = ('user', 'code', 'is_used', 'expires_at')
    list_filter = ('is_used',)
    readonly_fields = ('created_at',)