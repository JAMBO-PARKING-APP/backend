import os
import django
import sys

# Must set before importing any django models or components
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from django.test import RequestFactory
from django.contrib.auth.models import AnonymousUser
from apps.common.models import Country, set_current_country, get_current_country
from apps.parking.models import Zone
from apps.common.middleware import RegionalContextMiddleware

def test_regional_filtering():
    rf = RequestFactory()
    middleware = RegionalContextMiddleware(lambda r: None)
    
    # 1. Inspect Database State
    countries = list(Country.objects.all())
    if not countries:
        print("❌ CRITICAL: No countries found in database! The 'country separator' cannot work without data.")
        return

    print(f"📊 Database Stats:")
    print(f"   - Total Countries: {len(countries)}")
    print(f"   - Total Zones: {Zone.all_objects.count()}")

    # 2. Test Header Detection Logic directly (Mimic Middleware)
    for country in countries:
        print(f"\n🧪 Testing Country: {country.name} ({country.iso_code})")
        
        # Simulate request with Header
        # Note: RequestFactory uses HTTP_ prefix for custom headers
        request = rf.get('/', HTTP_X_COUNTRY_CODE=country.iso_code)
        request.user = AnonymousUser()
        
        # Manually run the core logic of the middleware
        country_id = request.headers.get('X-Country-ID') or request.headers.get('X-Country-Code')
        print(f"   - Detected Header Value: {country_id}")
        
        # Run middleware
        middleware(request)
        ctx_country = get_current_country()
        print(f"   - Context Country after Middleware: {ctx_country}")
        
        if ctx_country and ctx_country.id == country.id:
            print("   ✅ Middleware correctly identified country!")
            
            # Check Filtering
            filtered_zones = list(Zone.objects.all())
            actual_zones_for_country = list(Zone.all_objects.filter(country=country))
            print(f"   - Zones Displayed: {len(filtered_zones)}")
            print(f"   - Zones expected: {len(actual_zones_for_country)}")
            
            if len(filtered_zones) == len(actual_zones_for_country):
                print("   ✅ RegionalManager Filtering SUCCESS!")
            else:
                print("   ❌ RegionalManager Filtering FAILURE!")
        else:
            print("   ❌ Middleware FAILED to identify country.")

    # Cleanup
    set_current_country(None)

if __name__ == "__main__":
    test_regional_filtering()
