from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from apps.parking.models import Zone, Reservation
from apps.accounts.models import User, Vehicle
from apps.parking.services.reservation_service import ReservationService

class Command(BaseCommand):
    help = 'Verify ReservationService Logic'

    def handle(self, *args, **kwargs):
        self.stdout.write("Running ReservationService Verification...")
        
        # Setup Data
        user, _ = User.objects.get_or_create(email='test_res@example.com', defaults={'first_name': 'Test', 'password': 'pass'})
        vehicle, _ = Vehicle.objects.get_or_create(user=user, license_plate='TEST001')
        zone, _ = Zone.objects.get_or_create(
            name='Test Zone Reserved', 
            defaults={
                'hourly_rate': 1000, 
                'total_slots': 1,
                'latitude': 0, 
                'longitude': 0
            }
        )
        zone.total_slots = 1
        zone.save()
        
        # Cleanup
        Reservation.objects.filter(zone=zone).delete()

        now = timezone.now() + timedelta(hours=1)
        end = now + timedelta(hours=2)

        self.stdout.write(f"Zone Capacity: {zone.capacity}")

        # 1. Create First Reservation
        self.stdout.write("1. Creating first reservation...")
        try:
            res1 = ReservationService.create_reservation(vehicle, zone, now, end)
            self.stdout.write(self.style.SUCCESS(f"SUCCESS: Reservation created. Status: {res1.status}"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"FAILED: {e}"))
            return

        # 2. Confirm it
        res1.status = 'confirmed'
        res1.save()

        # 3. Create Overlapping Reservation
        self.stdout.write("2. Attempting overlapping reservation (Should Fail)...")
        try:
            vehicle2, _ = Vehicle.objects.get_or_create(user=user, license_plate='TEST002')
            ReservationService.create_reservation(vehicle2, zone, now, end)
            self.stdout.write(self.style.ERROR("FAILED: Overlapping reservation was allowed!"))
        except ValueError as e:
            self.stdout.write(self.style.SUCCESS(f"SUCCESS: Caught expected error: {e}"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"FAILED: Unexpected error: {e}"))

        # 4. Create Non-Overlapping Reservation
        self.stdout.write("3. Attempting non-overlapping future reservation (Should Succeed)...")
        try:
            future_start = end + timedelta(minutes=30)
            future_end = future_start + timedelta(hours=1)
            res3 = ReservationService.create_reservation(vehicle, zone, future_start, future_end)
            self.stdout.write(self.style.SUCCESS(f"SUCCESS: Reservation created. Status: {res3.status}"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"FAILED: {e}"))
