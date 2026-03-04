from django.core.management.base import BaseCommand
from django.core.cache import cache
from apps.parking.models import Zone, ParkingSession
from django.utils import timezone

class Command(BaseCommand):
    help = 'Warm frequently used caches (zones live status, quick lookups)'

    def handle(self, *args, **options):
        zones = Zone.objects.filter(is_active=True)
        now = timezone.now()
        for zone in zones:
            active_sessions = ParkingSession.objects.filter(zone=zone, status='active').select_related('vehicle', 'parking_slot')
            total_slots = zone.slots.count() or 50
            occupied_slots = active_sessions.count()

            sessions_data = []
            for session in active_sessions:
                remaining_seconds = (session.planned_end_time - now).total_seconds()
                remaining_seconds = max(0, remaining_seconds)
                remaining_minutes = int(remaining_seconds / 60)

                sessions_data.append({
                    'id': str(session.id),
                    'vehicle_plate': session.vehicle.license_plate,
                    'slot_code': session.parking_slot.slot_code if session.parking_slot else None,
                    'start_time': session.start_time.isoformat(),
                    'planned_end_time': session.planned_end_time.isoformat(),
                    'duration_minutes': session.duration_minutes,
                    'remaining_minutes': remaining_minutes,
                    'estimated_cost': float(session.estimated_cost)
                })

            result = {
                'zone_id': str(zone.id),
                'zone_name': zone.name,
                'total_slots': total_slots,
                'occupied_slots': occupied_slots,
                'available_slots': total_slots - occupied_slots,
                'occupancy_rate': (occupied_slots * 100) // total_slots if total_slots > 0 else 0,
                'active_sessions': sessions_data
            }

            try:
                cache.set(f"zone_live_{zone.id}", result, 10)
            except Exception:
                pass

        self.stdout.write(self.style.SUCCESS('Warmed zone live caches'))
