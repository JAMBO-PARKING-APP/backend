from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.common.models import Country
from apps.parking.models import Zone


DEMO_LOCATIONS = (
    {
        'country': {
            'name': 'Guinea',
            'iso_code': 'GN',
            'currency': 'GNF',
            'currency_symbol': 'FG',
            'timezone': 'Africa/Conakry',
            'phone_code': '+224',
            'flag_emoji': '🇬🇳',
            'latitude': Decimal('9.6412'),
            'longitude': Decimal('-13.5784'),
        },
        'zone': {
            'name': 'Conakry Central Demo Parking',
            'code': 'DGN001',
            'hourly_rate': Decimal('5000.00'),
            'latitude': Decimal('9.6412'),
            'longitude': Decimal('-13.5784'),
        },
    },
    {
        'country': {
            'name': 'Uganda',
            'iso_code': 'UG',
            'currency': 'UGX',
            'currency_symbol': 'USh',
            'timezone': 'Africa/Kampala',
            'phone_code': '+256',
            'flag_emoji': '🇺🇬',
            'latitude': Decimal('0.3476'),
            'longitude': Decimal('32.5825'),
        },
        'zone': {
            'name': 'Kampala Central Demo Parking',
            'code': 'DUG001',
            'hourly_rate': Decimal('2000.00'),
            'latitude': Decimal('0.3476'),
            'longitude': Decimal('32.5825'),
        },
    },
    {
        'country': {
            'name': 'Germany',
            'iso_code': 'DE',
            'currency': 'EUR',
            'currency_symbol': '€',
            'timezone': 'Europe/Berlin',
            'phone_code': '+49',
            'flag_emoji': '🇩🇪',
            'latitude': Decimal('52.5200'),
            'longitude': Decimal('13.4050'),
        },
        'zone': {
            'name': 'Berlin Central Demo Parking',
            'code': 'DDE001',
            'hourly_rate': Decimal('2.50'),
            'latitude': Decimal('52.5200'),
            'longitude': Decimal('13.4050'),
        },
    },
)


class Command(BaseCommand):
    help = 'Create or update demo parking zones in Guinea, Uganda, and Germany.'

    @transaction.atomic
    def handle(self, *args, **options):
        for location in DEMO_LOCATIONS:
            country, _ = Country.objects.update_or_create(
                iso_code=location['country']['iso_code'],
                defaults={**location['country'], 'is_active': True},
            )
            zone, created = Zone.all_objects.update_or_create(
                code=location['zone']['code'],
                defaults={
                    **location['zone'],
                    'country': country,
                    'description': (
                        f"Demo parking zone in {location['country']['name']}. "
                        'Created by the seed_demo_zones management command.'
                    ),
                    'total_slots': 10,
                    'is_active': True,
                    'supports_reservations': True,
                },
            )
            action = 'Created' if created else 'Updated'
            self.stdout.write(
                f'{action} {zone.name} ({country.iso_code}); '
                f'{zone.slots.count()} parking slots.'
            )

        self.stdout.write(self.style.SUCCESS('Demo zones are ready.'))
