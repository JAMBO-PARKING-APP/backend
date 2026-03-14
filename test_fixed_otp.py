import os
import django
import random
from django.utils import timezone
from datetime import timedelta
from django.core.mail import EmailMessage
from django.conf import settings

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.accounts.models import User, OTPCode

def test_fixed_otp():
    email_addr = "tutu.melchizedek8@gmail.com"
    
    try:
        print(f"Current Email Backend: {settings.EMAIL_BACKEND}")
        
        user, created = User.objects.get_or_create(
            email=email_addr,
            defaults={'phone': '+256708888888', 'first_name': 'Tutu', 'last_name': 'Gmail8', 'is_active': True}
        )
        
        otp_code = str(random.randint(100000, 999999))
        OTPCode.objects.filter(user=user, is_used=False).update(is_used=True)
        OTPCode.objects.create(
            user=user,
            code=otp_code,
            expires_at=timezone.now() + timedelta(minutes=10)
        )
        
        subject = "Your Jambo Park Verification Code (FIXED)"
        message = f"Your code is: {otp_code}\n\nThis confirms the backend fix works."
        html_content = f"""
        <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f9f9f9; border: 1px solid #eee; border-radius: 8px;">
            <h2 style="color: #2ecc71;">OTP Fixed!</h2>
            <p style="font-size: 18px;">Your verification code is: <strong style="font-size: 24px;">{otp_code}</strong></p>
            <p>If you see this, the SMTP inheritance bug is fixed and delivery is working.</p>
        </div>
        """
        
        print(f"Sending fixed OTP test to: {email_addr}")
        email = EmailMessage(
            subject=subject,
            body=message,
            from_email=f"Jambo Park <{settings.DEFAULT_FROM_EMAIL}>",
            to=[user.email],
            bcc=[settings.DEFAULT_FROM_EMAIL],
        )
        email.content_subtype = "html"
        email.body = html_content
        email.send(fail_silently=False)
        print(f"Success: OTP sent! Code: {otp_code}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_fixed_otp()
