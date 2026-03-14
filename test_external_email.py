import os
import django
from django.core.mail import EmailMessage
from django.conf import settings

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

def test_send_external_email():
    try:
        otp_code = "987654"
        recipient = "tutu.melchizedek@bodabodaunion.ug"
        subject = "Jambo Park External Verification Test"
        message = f"Your Jambo Park verification code is: {otp_code}\n\nThis code will expire in 10 minutes."
        html_content = f"""
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
            <h2 style="color: #2c3e50; text-align: center;">Jambo Park Test</h2>
            <p style="font-size: 16px; color: #34495e;">This is an external test of the new OTP delivery system. Please use the following code:</p>
            <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-radius: 5px; margin: 20px 0;">
                <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #2ecc71;">{otp_code}</span>
            </div>
            <p style="font-size: 14px; color: #7f8c8d; text-align: center;">This code will expire in 10 minutes.</p>
            <hr style="border: 0; border-top: 1px solid #eeeeee; margin: 20px 0;">
            <p style="font-size: 12px; color: #bdc3c7; text-align: center;">This is a system verification test.</p>
        </div>
        """
        
        print(f"Sending test email to external recipient: {recipient}")
        email = EmailMessage(
            subject=subject,
            body=message,
            from_email=f"Jambo Park <{settings.DEFAULT_FROM_EMAIL}>",
            to=[recipient],
            bcc=[settings.DEFAULT_FROM_EMAIL],
        )
        email.content_subtype = "html"
        email.body = html_content
        email.send(fail_silently=False)
        print("Success: External test email sent successfully!")
    except Exception as e:
        print(f"Error: Failed to send external test email. {e}")

if __name__ == "__main__":
    test_send_external_email()
