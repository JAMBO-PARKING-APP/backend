import os
import django
from django.core.mail import EmailMessage
from django.conf import settings

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

def test_final_branded_email():
    recipient = "tutu.melchizedek8@gmail.com"
    otp_code = "123456"
    subject = "Welcome to Space Park - Verify Your Account"
    message = f"Your Space Park verification code is: {otp_code}\n\nThis code will expire in 10 minutes."
    
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <body style="margin: 0; padding: 0; background-color: #f6f9fc; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="padding: 20px 0;">
            <tr>
                <td align="center">
                    <table border="0" cellpadding="0" cellspacing="0" width="600" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
                        <!-- Header with Logo -->
                        <tr>
                            <td align="center" style="padding: 40px 0 20px 0; background-color: #ffffff;">
                                <img src="https://iili.io/q0vCDYl.png" alt="Space Park Logo" width="150" style="display: block; outline: none; border: none; text-decoration: none;">
                            </td>
                        </tr>
                        <!-- Body -->
                        <tr>
                            <td style="padding: 20px 40px 40px 40px;">
                                <h1 style="color: #1a1f36; font-size: 24px; font-weight: 600; margin: 0; text-align: center;">Welcome to Space Park</h1>
                                <p style="color: #4f566b; font-size: 16px; line-height: 24px; margin-top: 20px; text-align: center;">
                                    Thank you for joining our elite parking network. To secure your account and complete your registration, please use the verification code below.
                                </p>
                                
                                <div style="margin: 30px 0; padding: 25px; background-color: #f8fbff; border-radius: 8px; text-align: center;">
                                    <span style="font-family: monospace; font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #5469d4;">{otp_code}</span>
                                </div>
                                
                                <p style="color: #697386; font-size: 14px; line-height: 20px; text-align: center;">
                                    This code is valid for <strong>10 minutes</strong>. For security, never share this code with anyone.
                                </p>
                            </td>
                        </tr>
                        <!-- Footer -->
                        <tr>
                            <td style="padding: 20px 40px; background-color: #f7fafc; text-align: center; border-top: 1px solid #e3e8ee;">
                                <p style="color: #a3acb9; font-size: 12px; margin: 0;">&copy; 2026 Space Park Systems. All rights reserved.</p>
                                <p style="color: #a3acb9; font-size: 12px; margin: 5px 0 0 0;">You received this because you registered for a Space Park account.</p>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </body>
    </html>
    """
    
    try:
        print(f"Sending final branded test email to: {recipient}")
        email = EmailMessage(
            subject=subject,
            body=message,
            from_email=f"Space Park <{settings.DEFAULT_FROM_EMAIL}>",
            to=[recipient],
            bcc=[settings.DEFAULT_FROM_EMAIL],
        )
        email.content_subtype = "html"
        email.body = html_content
        email.send(fail_silently=False)
        print("Success: Final branded test email sent successfully!")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_final_branded_email()
