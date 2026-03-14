import smtplib
from email.mime.text import MIMEText

def test_smtp_ssl():
    host = "smtp.gmail.com"
    port = 465
    user = "union.crm.products@gmail.com"
    password = "wqho syjf yslr esmj"
    to_email = "tutu.melchizedek@bodabodaunion.ug"
    
    msg = MIMEText("This is a test email using Port 465 (SSL).")
    msg['From'] = user
    msg['To'] = to_email
    msg['Subject'] = "SMTP SSL Test"
    
    try:
        print(f"Connecting to {host}:{port} (SSL)...")
        server = smtplib.SMTP_SSL(host, port)
        print(f"Logging in as {user}...")
        server.login(user, password)
        print(f"Sending email to {to_email}...")
        server.send_message(msg)
        server.quit()
        print("Success: SSL Test email sent successfully!")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_smtp_ssl()
