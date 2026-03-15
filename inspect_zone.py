import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
import django
django.setup()

from apps.zone_owner_portal.models import ZoneApplicationPublic

email = "tutumelchizedek8@gmail.com".lower()
app = ZoneApplicationPublic.objects.filter(applicant_email__iexact=email).first()

if app and app.created_zone:
    zone = app.created_zone
    print(f"ZONE CREATED:")
    print(f"  Name: {zone.name}")
    print(f"  Type: {zone.zone_type}")
    print(f"  Country: {zone.country.name if zone.country else 'NONE'}")
    print(f"  Lat/Lng: {zone.latitude}, {zone.longitude}")
    print(f"  Rate: {zone.hourly_rate}")
    print(f"  Slots: {zone.total_slots}")
else:
    print("Zone not linked or app not found.")
