import os
import django
from decimal import Decimal
from django.utils import timezone
from django.test import RequestFactory

# Setup Django
import sys
project_root = 'C:\\Users\\tutum\\Downloads\\JAMBO PARK'
if project_root not in sys.path:
    sys.path.append(project_root)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
django.setup()

from apps.parking.models import ParkingSession, Zone
from apps.common.constants import ParkingStatus, UserRole
from apps.parking.api_views_officer import verify_qr_code
from apps.accounts.models import User

def debug_qr():
    print("--- Testing QR Data and Verification ---")
    s = ParkingSession.objects.filter(status=ParkingStatus.ACTIVE).first()
    if not s:
        print("No active session found. Finding any session...")
        s = ParkingSession.objects.first()
    
    if s:
        print(f"Session ID: {s.id}")
        print(f"Status: {s.status}")
        try:
            # Re-fetch to ensure we have the latest version of the model class
            s = ParkingSession.objects.get(id=s.id)
            qr_data = s.qr_code_data
            print(f"QR Data Gen SUCCESS:\n{qr_data}")
        except Exception as e:
            import traceback
            print(f"QR Data Gen FAILED: {str(e)}")
            traceback.print_exc()
            return

        # Test verification API
        officer = User.objects.filter(role=UserRole.OFFICER).first()
        if not officer:
            print("No officer found for testing")
            # If no officer, try to create one or use any user for logic check
            user = User.objects.first()
            if user:
                print(f"Testing with user: {user.phone} (Role: {user.role})")
                officer = user
            else:
                return
            
        rf = RequestFactory()
        # Ensure we pass a string ID if needed, though UUID is fine
        request = rf.post('/api/officer/verify-qr/', {'session_id': str(s.id)}, content_type='application/json')
        request.user = officer
        
        try:
            response = verify_qr_code(request)
            print(f"API Response: {response.status_code} - {response.data}")
        except Exception as e:
            import traceback
            print(f"API Call FAILED: {str(e)}")
            traceback.print_exc()

    else:
        print("No sessions total found in database")

def debug_end_session_url():
    print("\n--- Testing End Session Resolution ---")
    from django.urls import resolve
    from django.urls.exceptions import Resolver404
    
    url = '/api/user/parking/end/'
    try:
        match = resolve(url)
        print(f"URL {url} resolves to: {match.view_name}")
    except Resolver404:
        print(f"URL {url} NOT resolved")

if __name__ == "__main__":
    debug_qr()
    debug_end_session_url()
