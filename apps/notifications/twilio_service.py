import os
from . import tasks
from twilio.rest import Client

def get_twilio_client():
    account_sid = os.environ.get('TWILIO_ACCOUNT_SID')
    auth_token = os.environ.get('TWILIO_AUTH_TOKEN')
    if not account_sid or not auth_token:
        raise RuntimeError('Twilio credentials not configured in environment')
    return Client(account_sid, auth_token)

def send_verification_sync(to_phone: str, channel: str = 'sms', service_sid: str = None):
    client = get_twilio_client()
    service_sid = service_sid or os.environ.get('TWILIO_VERIFY_SERVICE_SID')
    if not service_sid:
        raise RuntimeError('TWILIO_VERIFY_SERVICE_SID not configured')

    verification = client.verify.v2.services(service_sid).verifications.create(
        to=to_phone,
        channel=channel
    )
    return verification

class MockVerification:
    def __init__(self, sid, status):
        self.sid = sid
        self.status = status

def send_verification(to_phone: str, channel: str = 'sms', service_sid: str = None):
    # Call the Celery task
    tasks.send_twilio_verification_task.delay(to_phone, channel)
    # Return a mock verification object so API views don't crash
    return MockVerification(sid='async_queued', status='pending')

def check_verification(to_phone: str, code: str, service_sid: str = None):
    client = get_twilio_client()
    service_sid = service_sid or os.environ.get('TWILIO_VERIFY_SERVICE_SID')
    if not service_sid:
        raise RuntimeError('TWILIO_VERIFY_SERVICE_SID not configured')

    check = client.verify.v2.services(service_sid).verification_checks.create(
        to=to_phone,
        code=code
    )
    return check
