import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_smtp_verbose():
    # Credentials
    host = "smtp.gmail.com"
    port = 587
    user = "union.crm.products@gmail.com"
    password = "wqho syjf yslr esmj"
    to_email = "tutu.melchizedek@bodabodaunion.ug"
    
    # Message
    msg = MIMEMultipart()
    msg['From'] = f"Jambo Park <{user}>"
    msg['To'] = to_email
    msg['Subject'] = "SMTP Verbose Debug Test"
    
    body = "This is a verbose debug test to trace the SMTP conversation."
    msg.attach(MIMEText(body, 'plain'))
    
    try:
        print(f"Connecting to {host}:{port}...")
        server = smtplib.SMTP(host, port)
        server.set_debuglevel(1)  # Enable verbose output
        
        print("Starting TLS...")
        server.starttls()
        
        print(f"Logging in as {user}...")
        server.login(user, password)
        
        print(f"Sending email to {to_email}...")
        server.send_message(msg)
        
        server.quit()
        print("\nSuccess: SMTP conversation completed and message accepted by Gmail.")
    except Exception as e:
        print(f"\nError: SMTP failed. {e}")

if __name__ == "__main__":
    test_smtp_verbose()
