import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
import django
django.setup()

from apps.accounts.models import User
from apps.zone_owner_portal.models import ZoneApplicationPublic

with open('inspect_output_utf8.txt', 'w', encoding='utf-8') as f:
    f.write("="*50 + "\n")
    f.write("ALL ZONE APPLICATIONS\n")
    f.write("="*50 + "\n")
    for app in ZoneApplicationPublic.objects.all():
        f.write(f"[{app.application_id}] Status: {app.status}\n")
        f.write(f"  Email: '{app.applicant_email}'\n")
        f.write(f"  Phone: '{app.applicant_phone}'\n")
        f.write(f"  Zone ID: {app.created_zone_id}\n")
        f.write(f"  Demo PWD: {app.demo_password}\n")
        f.write("-" * 30 + "\n")

    f.write("="*50 + "\n")
    f.write("USERS MATCHING EMAIL OR PHONE\n")
    f.write("="*50 + "\n")
    target_email = "tutumelchizedek8@gmail.com".lower()

    for u in User.objects.all().order_by('-pk')[:50]:
        u_email = u.email.lower() if u.email else ""
        if target_email in u_email or u.is_staff is False:
            f.write(f"User ID: {u.id} | Email: '{u.email}' | Phone: '{u.phone}' | Role: '{u.role}' | Active: {u.is_active}\n")

    f.write("="*50 + "\n")
    user_exact = User.objects.filter(email__iexact=target_email).first()
    if user_exact:
        f.write(f"EXACT MATCH FOUND: {user_exact.email} / {user_exact.phone}\n")
    else:
        f.write(f"NO EXACT MATCH FOR: {target_email}\n")
    f.write("="*50 + "\n")
