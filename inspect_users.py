from apps.accounts.models import User
from apps.zone_owner_portal.models import ZoneApplicationPublic

print("-" * 50)
print("CHECKING USERS:")
for u in User.objects.all():
    print(f"USER: ID={u.id} | Email={u.email} | Phone={u.phone} | Role={u.role}")

print("-" * 50)
print("CHECKING APPLICATIONS:")
for app in ZoneApplicationPublic.objects.all():
    print(f"APP: ID={app.application_id} | Email={app.applicant_email} | Phone={app.applicant_phone} | Status={app.status} | ZoneID={app.created_zone_id}")
print("-" * 50)
