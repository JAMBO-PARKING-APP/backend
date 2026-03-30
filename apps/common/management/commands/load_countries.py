import json
import os
from django.core.management.base import BaseCommand
from django.conf import settings
from apps.common.models import Country

class Command(BaseCommand):
    help = 'Load countries into the database from global_countries.json'

    def handle(self, *args, **kwargs):
        json_path = os.path.join(settings.BASE_DIR, 'global_countries.json')
        
        if not os.path.exists(json_path):
            self.stderr.write(self.style.ERROR(f"File not found: {json_path}"))
            return

        with open(json_path, 'r', encoding='utf-8') as file:
            try:
                data = json.load(file)
            except json.JSONDecodeError as e:
                self.stderr.write(self.style.ERROR(f"Invalid JSON format: {e}"))
                return

        countries_created = 0
        countries_updated = 0

        for item in data:
            name = item.get('name', {}).get('common', '')
            iso_code = item.get('cca2', '')
            
            # Extract currency and symbol
            currencies = item.get('currencies', {})
            currency_code = list(currencies.keys())[0] if currencies else 'USD'
            currency_symbol = currencies.get(currency_code, {}).get('symbol', '$') if currencies else '$'
            
            # Extract phone dialing code
            idd = item.get('idd', {})
            root = idd.get('root', '')
            suffixes = idd.get('suffixes', [])
            phone_code = f"{root}{suffixes[0]}" if (root and suffixes) else root
            
            flag_emoji = item.get('flag', '')
            
            timezone = 'UTC' 

            if name and iso_code:
                country, created = Country.objects.update_or_create(
                    iso_code=iso_code,
                    defaults={
                        'name': name,
                        'currency': currency_code[:3],
                        'currency_symbol': currency_symbol[:10],
                        'phone_code': phone_code[:10],
                        'flag_emoji': flag_emoji[:10],
                        'timezone': timezone,
                        'is_active': True
                    }
                )
                
                if created:
                    countries_created += 1
                else:
                    countries_updated += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully loaded countries! Created: {countries_created}, Updated: {countries_updated}'
            )
        )
