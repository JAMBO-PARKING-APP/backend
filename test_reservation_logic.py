import os
import django
from django.utils import timezone
from datetime import timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from apps.parking.models import Zone, Reservation, ParkingSlot
from apps.accounts.models import User, Vehicle
from apps.parking.services.reservation_service import ReservationService

def run_test():
    print("Running ReservationService Verification...")
    
    # Setup Data
    user, _ = User.objects.get_or_create(email='test_res@example.com', defaults={'first_name': 'Test', 'password': 'pass'})
    vehicle, _ = Vehicle.objects.get_or_create(user=user, license_plate='TEST001')
    zone, _ = Zone.objects.get_or_create(
        name='Test Zone Reserved', 
        defaults={
            'hourly_rate': 1000, 
            'total_slots': 1,  # Only 1 slot to test capacity
            'latitude': 0, 
            'longitude': 0
        }
    )
    # Ensure capacity is 1
    zone.total_slots = 1
    zone.save()
    
    # Cleanup previous reservations
    Reservation.objects.filter(zone=zone).delete()

    now = timezone.now() + timedelta(hours=1) # Future booking
    end = now + timedelta(hours=2)

    print(f"Zone Capacity: {zone.capacity}")

    # 1. Create First Reservation
    print("1. Creating first reservation...")
    try:
        res1 = ReservationService.create_reservation(vehicle, zone, now, end)
        print(f"SUCCESS: Reservation created. Status: {res1.status}")
    except Exception as e:
        print(f"FAILED: {e}")
        return

    # 2. Confirm it (to occupy capacity)
    res1.status = 'confirmed'
    res1.save()

    # 3. Create Overlapping Reservation
    print("2. Attempting overlapping reservation (Should Fail)...")
    try:
        # Use a different vehicle just in case
        vehicle2, _ = Vehicle.objects.get_or_create(user=user, license_plate='TEST002')
        ReservationService.create_reservation(vehicle2, zone, now, end)
        print("FAILED: Overlapping reservation was allowed!")
    except ValueError as e:
        print(f"SUCCESS: Caught expected error: {e}")
    except Exception as e:
        print(f"FAILED: Unexpected error: {e}")

    # 4. Create Non-Overlapping Reservation
    print("3. Attempting non-overlapping future reservation (Should Succeed)...")
    try:
        future_start = end + timedelta(minutes=30)
        future_end = future_start + timedelta(hours=1)
        res3 = ReservationService.create_reservation(vehicle, zone, future_start, future_end)
        print(f"SUCCESS: Reservation created. Status: {res3.status}")
    except Exception as e:
        print(f"FAILED: {e}")

if __name__ == '__main__':
    run_test()
