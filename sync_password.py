import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
import django
django.setup()

from apps.accounts.models import User
from apps.zone_owner_portal.models import ZoneApplicationPublic

email = "tutumelchizedek8@gmail.com".lower()
app = ZoneApplicationPublic.objects.filter(applicant_email__iexact=email).first()
user = User.objects.filter(email__iexact=email).first()

if app and user:
    pwd = app.demo_password
    print(f"Syncing password for user {user.email} to application demo_password.")
    user.set_password(pwd)
    user.save(update_fields=['password'])
    print(f"Password overridden successfully. Try logging in with the password shown in admin.")
else:
    print("User or App not found.")
