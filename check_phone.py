import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
import django
django.setup()

from apps.accounts.models import User

phone = "+256742531052"
user_by_phone = User.objects.filter(phone=phone).first()

if user_by_phone:
    print(f"USER BY PHONE EXISTS:")
    print(f"ID: {user_by_phone.id}")
    print(f"Email: {user_by_phone.email}")
    print(f"Phone: {user_by_phone.phone}")
else:
    print("NO USER FOUND BY PHONE")
