from django.http import JsonResponse
from django.utils import timezone
from django.views import View
from django.utils.translation import gettext as _

from apps.common.permissions import AdminRequiredMixin
from apps.common.constants import ParkingStatus
from apps.parking.models import Zone, ParkingSession
from apps.common.utils import get_user_local_time

class ZoneLiveStatusAjaxView(AdminRequiredMixin, View):
    """
    AJAX view to get real-time status of a parking zone, 
    including slot occupancy and active sessions.
    """
    def get(self, request, zone_id):
        try:
            zone = Zone.objects.get(pk=zone_id)
            active_sessions = ParkingSession.objects.filter(
                zone=zone,
                status=ParkingStatus.ACTIVE
            ).select_related('vehicle', 'parking_slot')
            all_slots = zone.slots.all()
            slots_data = []
            occupied_slots = {session.parking_slot_id: session for session in active_sessions if session.parking_slot_id}
            
            for slot in all_slots:
                if slot.id in occupied_slots:
                    session = occupied_slots[slot.id]
                    slots_data.append({
                        'id': slot.slot_code or str(slot.id),
                        'status': 'occupied',
                        'vehicle': session.vehicle.license_plate
                    })
                else:
                    slots_data.append({
                        'id': slot.slot_code or str(slot.id),
                        'status': 'available',
                        'vehicle': None
                    })
            
            if not all_slots.exists():
                total_slots = min(100, max(50, active_sessions.count() * 2))
                slots_data = []
                
                for i in range(1, total_slots + 1):
                    if i <= active_sessions.count():
                        session = list(active_sessions)[i-1]
                        slots_data.append({
                            'id': f'S{i:02d}',
                            'status': 'occupied',
                            'vehicle': session.vehicle.license_plate
                        })
                    else:
                        slots_data.append({
                            'id': f'S{i:02d}',
                            'status': 'available',
                            'vehicle': None
                        })
            
            active_sessions_list = []
            for session in active_sessions:
                duration = timezone.now() - session.start_time
                hours, remainder = divmod(duration.total_seconds(), 3600)
                minutes, _ = divmod(remainder, 60)
                
                local_start = get_user_local_time(session.vehicle.user, session.start_time)
                
                active_sessions_list.append({
                    'vehicle': session.vehicle.license_plate,
                    'slot': session.parking_slot.slot_code if session.parking_slot else 'N/A',
                    'start_time': local_start.strftime('%H:%M'),
                    'duration': f"{int(hours)}h {int(minutes)}m" if hours > 0 else f"{int(minutes)}m"
                })
            
            occupied_count = len([s for s in slots_data if s['status'] == 'occupied'])
            total_slots_count = len(slots_data)
            
            data = {
                'zone_name': zone.name,
                'total_slots': total_slots_count,
                'occupied_slots': occupied_count,
                'active_sessions': active_sessions.count(),
                'slots': slots_data,
                'active_sessions_list': active_sessions_list
            }
            
            return JsonResponse(data)
            
        except Zone.DoesNotExist:
            return JsonResponse({'error': _('Zone not found')}, status=404)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)