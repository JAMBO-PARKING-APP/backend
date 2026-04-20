from django.utils import timezone
from decimal import Decimal
from datetime import timedelta


class AnalyticsService:
    @staticmethod
    def get_realtime_metrics():
        """Fetch high-level business metrics grouped by country."""
        from django.db.models import Sum
        from apps.parking.models import Zone, ParkingSession
        from apps.payments.models import Transaction
        from apps.enforcement.models import Violation, OfficerStatus
        from apps.common.models import Country
        from apps.common.constants import ParkingStatus, TransactionStatus

        now = timezone.now()
        start_of_today = now.replace(hour=0, minute=0, second=0, microsecond=0)
        
        active_countries = Country.objects.filter(is_active=True)
        stats = {}
        
        for country in active_countries:
            # 1. Parking Occupancy
            zones = Zone.objects.filter(country=country, is_active=True)
            total_slots = zones.aggregate(total=Sum('total_slots'))['total'] or 0
            active_sessions = ParkingSession.objects.filter(
                country=country, 
                status=ParkingStatus.ACTIVE
            ).count()
            
            occupancy_rate = (active_sessions / total_slots * 100) if total_slots > 0 else 0
            
            # 2. Revenue Today (Transactions + Wallet Payments)
            # We look for completed transactions today
            revenue_today = Transaction.objects.filter(
                country=country,
                status=TransactionStatus.COMPLETED,
                created_at__gte=start_of_today
            ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
            
            # 3. Enforcement Presence
            online_officers = OfficerStatus.objects.filter(
                officer__country=country,
                is_online=True
            ).count()
            
            violations_today = Violation.objects.filter(
                country=country,
                created_at__gte=start_of_today
            ).count()
            
            # 4. Activity Pulse (Last 15 minutes)
            fifteen_mins_ago = now - timedelta(minutes=15)
            recent_sessions = ParkingSession.objects.filter(
                country=country,
                start_time__gte=fifteen_mins_ago
            ).count()
            
            stats[country.iso_code] = {
                'country_name': country.name,
                'country_flag': country.flag_emoji,
                'currency': country.currency,
                'business': {
                    'active_sessions': active_sessions,
                    'total_slots': total_slots,
                    'occupancy_rate': round(occupancy_rate, 1),
                    'revenue_today': float(revenue_today),
                },
                'enforcement': {
                    'online_officers': online_officers,
                    'violations_today': violations_today,
                },
                'activity': {
                    'recent_starts': recent_sessions,
                }
            }
            
        return stats

    @staticmethod
    def get_unified_event_feed(limit=15):
        """Fetch the most recent significant events across all countries."""
        from apps.parking.models import ParkingSession
        from apps.enforcement.models import Violation
        from apps.payments.models import Transaction
        from apps.common.constants import TransactionStatus

        feed = []
        
        # Recent sessions
        sessions = ParkingSession.objects.select_related('zone', 'country', 'vehicle').order_by('-created_at')[:limit]
        for s in sessions:
            feed.append({
                'type': 'session',
                'title': f'{s.vehicle.license_plate if s.vehicle else "Guest"} started parking',
                'zone': s.zone.name,
                'country': s.country.iso_code if s.country else '??',
                'time': s.created_at.isoformat(),
                'icon': '🚗'
            })
            
        # Recent violations
        violations = Violation.objects.select_related('zone', 'country', 'vehicle').order_by('-created_at')[:limit]
        for v in violations:
            feed.append({
                'type': 'violation',
                'title': f'Violation issued: {v.violation_type}',
                'zone': v.zone.name,
                'country': v.country.iso_code if v.country else '??',
                'time': v.created_at.isoformat(),
                'icon': '🚨'
            })
            
        # Recent payments
        payments = Transaction.objects.filter(status=TransactionStatus.COMPLETED).select_related('country', 'user').order_by('-created_at')[:limit]
        for p in payments:
            feed.append({
                'type': 'payment',
                'title': f'Payment of {p.amount} {p.country.currency if p.country and hasattr(p.country, "currency") else ""}',
                'user': p.user.phone if p.user else "Anonymous",
                'country': getattr(p.country, 'iso_code', '??'),
                'time': p.created_at.isoformat(),
                'icon': '💰'
            })
            
        feed.sort(key=lambda x: x['time'], reverse=True)
        return feed[:limit]
