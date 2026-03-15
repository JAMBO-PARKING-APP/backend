import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
import django
django.setup()

from django.db import transaction
from apps.zone_owner_portal.models import ZoneApplicationPublic

email = "tutumelchizedek8@gmail.com".lower()
app = ZoneApplicationPublic.objects.filter(applicant_email__iexact=email).first()

if not app:
    print(f"Application for '{email}' not found.")
else:
    print(f"Found application: {app.application_id}")
    print(f"Current status: {app.status}")
    print(f"Current zone: {app.created_zone_id}")
    
    # We force the signal to trigger
    with transaction.atomic():
        app.status = 'approved'
        app.save(update_fields=['status'])  # this triggers post_save
    
    print("Save triggered. If on_commit logic ran, it should be working.")
