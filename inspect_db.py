import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
import django
django.setup()

from apps.accounts.models import User
from apps.zone_owner_portal.models import ZoneApplicationPublic

print("="*50)
print("ALL ZONE APPLICATIONS")
print("="*50)
for app in ZoneApplicationPublic.objects.all():
    print(f"[{app.application_id}] Status: {app.status}")
    print(f"  Email: '{app.applicant_email}'")
    print(f"  Phone: '{app.applicant_phone}'")
    print(f"  Zone ID: {app.created_zone_id}")
    print(f"  Demo PWD: {app.demo_password}")
    print("-" * 30)

print("="*50)
print("USERS MATCHING EMAIL OR PHONE")
print("="*50)
target_email = "tutumelchizedek8@gmail.com".lower()

for u in User.objects.all().order_by('-pk')[:50]:
    u_email = u.email.lower() if u.email else ""
    if target_email in u_email or u.is_staff is False:
        print(f"User ID: {u.id} | Email: '{u.email}' | Phone: '{u.phone}' | Role: '{u.role}' | Active: {u.is_active}")

print("="*50)
user_exact = User.objects.filter(email__iexact=target_email).first()
if user_exact:
    print(f"EXACT MATCH FOUND: {user_exact.email} / {user_exact.phone}")
else:
    print(f"NO EXACT MATCH FOR: {target_email}")
print("="*50)
