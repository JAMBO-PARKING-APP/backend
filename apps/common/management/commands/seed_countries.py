from django.core.management.base import BaseCommand
from apps.common.models import Country

class Command(BaseCommand):
    help = 'Seeds the database with global country data'

    def handle(self, *args, **kwargs):
        import json
        import os
        from django.conf import settings

        json_path = os.path.join(settings.BASE_DIR, 'global_countries.json')
        
        if not os.path.exists(json_path):
            self.stdout.write(self.style.ERROR(f'JSON file not found at {json_path}'))
            return

        with open(json_path, 'r', encoding='utf-8') as f:
            countries_data = json.load(f)

        self.stdout.write(f'Start seeding {len(countries_data)} countries from JSON...')
        
        count = 0
        for data in countries_data:
            try:
                # Extract fields
                name = data.get('name', {}).get('common', 'Unknown')
                iso_code = data.get('cca2')
                flag_emoji = data.get('flag', '')
                
                # Extract Currency
                currencies = data.get('currencies', {})
                currency_code = 'USD'
                currency_symbol = '$'
                if currencies:
                    # Take the first currency
                    currency_code = list(currencies.keys())[0]
                    currency_symbol = currencies[currency_code].get('symbol', '$')
                
                # Extract Phone Code
                idd = data.get('idd', {})
                root = idd.get('root', '')
                suffixes = idd.get('suffixes', [])
                
                if not root:
                    # Skip if no phone code (e.g. Antarctica sometimes)
                    # continue
                    phone_code = ''
                elif len(suffixes) == 1:
                    phone_code = f"{root}{suffixes[0]}"
                else:
                    phone_code = root # e.g. +1 for US/Canada/etc

                if not iso_code:
                    continue

                Country.objects.update_or_create(
                    iso_code=iso_code,
                    defaults={
                        'name': name,
                        'currency': currency_code,
                        'currency_symbol': currency_symbol,
                        'phone_code': phone_code,
                        'flag_emoji': flag_emoji
                    }
                )
                count += 1
            except Exception as e:
                self.stdout.write(self.style.WARNING(f'Skipped {name}: {str(e)}'))
            
        self.stdout.write(self.style.SUCCESS(f'Successfully seeded {count} countries'))
