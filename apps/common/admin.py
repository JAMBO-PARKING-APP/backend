from django.contrib import admin
from .models import Country

@admin.register(Country)
class CountryAdmin(admin.ModelAdmin):
    list_display = ('name', 'iso_code', 'phone_code', 'currency', 'is_active')
    list_filter = ('is_active', 'currency')
    search_fields = ('name', 'iso_code', 'phone_code')
    ordering = ('name',)
    list_editable = ('is_active',)
