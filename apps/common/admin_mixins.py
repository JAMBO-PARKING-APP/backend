from django.contrib import admin

class RegionalAdminMixin:
    """
    Mixin for ModelAdmin to enforce regional access control.
    - Superusers see ALL data.
    - Regional Admins see ONLY data for their country.
    - Regional Admins automatically assign their country to new objects.
    """
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        
        # Superusers see everything
        if request.user.is_superuser:
            return qs
            
        # Regional Admins seeing their country's data
        if request.user.country:
            # Check if model has 'country' field
            if hasattr(self.model, 'country'):
                return qs.filter(country=request.user.country)
                
        # Fallback: strict secure default (see nothing if no country assigned)
        return qs.none() 

    def save_model(self, request, obj, form, change):
        # Automatically assign country for non-superusers if missing
        if not request.user.is_superuser and request.user.country:
            if hasattr(obj, 'country') and not obj.country:
                obj.country = request.user.country
                
        super().save_model(request, obj, form, change)
    
    def get_list_display(self, request):
        list_display = super().get_list_display(request)
        # Add country column for superusers if not present
        if request.user.is_superuser and 'country' not in list_display:
            if isinstance(list_display, tuple):
                 return list_display + ('country',)
            elif isinstance(list_display, list):
                 return list_display + ['country']
        return list_display
