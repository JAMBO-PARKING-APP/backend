import smtplib
from email.mime.text import MIMEText

def test_self_send():
    host = "smtp.gmail.com"
    port = 587
    user = "union.crm.products@gmail.com"
    password = "wqho syjf yslr esmj"
    
    msg = MIMEText("This is a self-test email to verify SMTP delivery to the account itself.")
    msg['From'] = user
    msg['To'] = user
    msg['Subject'] = "Self SMTP Test"
    
    try:
        server = smtplib.SMTP(host, port)
        server.starttls()
        server.login(user, password)
        server.send_message(msg)
        server.quit()
        print("Success: Self-test email sent successfully!")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_self_send()
