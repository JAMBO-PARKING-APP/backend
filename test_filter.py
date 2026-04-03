import os
import django
from django.test import RequestFactory
from django.contrib.auth.models import AnonymousUser

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from apps.common.models import Country, set_current_country, get_current_country
from apps.parking.models import Zone
from apps.common.middleware import RegionalContextMiddleware

def test_regional_filtering():
    rf = RequestFactory()
    middleware = RegionalContextMiddleware(lambda r: None)
    
    countries = list(Country.objects.all())
    if not countries:
        print("❌ No countries found in database!")
        return

    print(f"✅ Found {len(countries)} countries.")
    
    # Test 1: No Header, Authenticated User
    print("\n--- Test 1: No Header ---")
    request = rf.get('/')
    request.user = AnonymousUser()
    request.session = {}
    middleware(request)
    print(f"Current Country: {get_current_country()}")
    print(f"Zone Count: {Zone.objects.count()}")

    # Test 2: With X-Country-Code Header
    for country in countries:
        print(f"\n--- Test 2: Header X-Country-Code={country.iso_code} ---")
        request = rf.get('/', HTTP_X_COUNTRY_CODE=country.iso_code)
        request.user = AnonymousUser()
        request.session = {}
        middleware(request)
        print(f"Current Country: {get_current_country()}")
        # Check if Zones are correctly filtered
        filtered_count = Zone.objects.count()
        total_in_db = Zone.all_objects.filter(country=country).count()
        print(f"Filtered Zone Count: {filtered_count} / {total_in_db}")
        if filtered_count != total_in_db:
             print("❌ MISMATCH! Filtering is not working as expected.")
        else:
             print("✅ Filtering works for this country.")

    set_current_country(None)

if __name__ == "__main__":
    test_regional_filtering()
