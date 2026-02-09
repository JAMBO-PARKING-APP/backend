from django.core.management.base import BaseCommand
from django.utils import timezone
from decimal import Decimal
from apps.accounts.models import User, Vehicle
from apps.parking.models import Zone, ParkingSlot, ParkingSession
from apps.common.constants import UserRole, ParkingStatus

class Command(BaseCommand):
    help = 'Create test data for zones and parking sessions'

    def handle(self, *args, **options):
        # Create test zones if they don't exist
        if not Zone.objects.exists():
            self.stdout.write('Creating test zones...')
            
            zones_data = [
                {
                    'name': 'Downtown Plaza',
                    'description': 'Main downtown parking area',
                    'hourly_rate': Decimal('5.00'),
                    'latitude': Decimal('40.7128'),
                    'longitude': Decimal('-74.0060'),
                },
                {
                    'name': 'Shopping Center',
                    'description': 'Mall parking zone',
                    'hourly_rate': Decimal('3.50'),
                    'latitude': Decimal('40.7589'),
                    'longitude': Decimal('-73.9851'),
                },
                {
                    'name': 'Business District',
                    'description': 'Office building parking',
                    'hourly_rate': Decimal('8.00'),
                    'latitude': Decimal('40.7505'),
                    'longitude': Decimal('-73.9934'),
                }
            ]
            
            for zone_data in zones_data:
                zone = Zone.objects.create(**zone_data)
                self.stdout.write(f'Created zone: {zone.name}')
                
                # Create slots for each zone
                for i in range(1, 21):  # 20 slots per zone
                    slot = ParkingSlot.objects.create(
                        zone=zone,
                        slot_code=f'A{i:02d}',
                        diagram_x=50 + (i % 5) * 80,
                        diagram_y=50 + (i // 5) * 100
                    )
                
                self.stdout.write(f'Created 20 slots for {zone.name}')
        
        # Create test users and vehicles if they don't exist
        if not User.objects.filter(role=UserRole.DRIVER).exists():
            self.stdout.write('Creating test users and vehicles...')
            
            users_data = [
                {'phone': '+1234567890', 'first_name': 'John', 'last_name': 'Doe'},
                {'phone': '+1234567891', 'first_name': 'Jane', 'last_name': 'Smith'},
                {'phone': '+1234567892', 'first_name': 'Bob', 'last_name': 'Johnson'},
            ]
            
            for user_data in users_data:
                user = User.objects.create_user(
                    username=user_data['phone'],
                    **user_data,
                    role=UserRole.DRIVER,
                    is_verified=True
                )
                
                # Create vehicle for each user
                Vehicle.objects.create(
                    user=user,
                    license_plate=f'ABC{user.id:03d}',
                    make='Toyota',
                    model='Camry',
                    color='Blue'
                )
                
                self.stdout.write(f'Created user and vehicle: {user.full_name}')
        
        # Create some active parking sessions
        zones = Zone.objects.all()
        vehicles = Vehicle.objects.all()
        
        if zones.exists() and vehicles.exists():
            self.stdout.write('Creating active parking sessions...')
            
            # Clear existing active sessions
            ParkingSession.objects.filter(status=ParkingStatus.ACTIVE).delete()
            
            # Create some active sessions
            for i, vehicle in enumerate(vehicles[:5]):  # First 5 vehicles
                zone = zones[i % zones.count()]
                slots = zone.slots.all()
                
                if slots.exists():
                    slot = slots[i % slots.count()]
                    
                    session = ParkingSession.objects.create(
                        vehicle=vehicle,
                        zone=zone,
                        parking_slot=slot,
                        start_time=timezone.now() - timezone.timedelta(hours=i+1),
                        planned_end_time=timezone.now() + timezone.timedelta(hours=2),
                        estimated_cost=zone.hourly_rate * 3,
                        status=ParkingStatus.ACTIVE
                    )
                    
                    self.stdout.write(f'Created active session: {vehicle.license_plate} in {zone.name}')
        
        self.stdout.write(self.style.SUCCESS('Test data created successfully!'))