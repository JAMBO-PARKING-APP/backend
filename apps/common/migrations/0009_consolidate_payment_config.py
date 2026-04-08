# Generated manually for consolidating payment config into Country model

from django.db import migrations, models


def migrate_country_config_data(apps, schema_editor):
    """Migrate data from CountryConfig to Country model"""
    Country = apps.get_model('common', 'Country')
    CountryConfig = apps.get_model('common', 'CountryConfig')
    
    for config in CountryConfig.objects.all():
        country = config.country
        country.payment_methods = config.payment_methods
        country.exchange_rate_to_base = config.exchange_rate_to_base
        country.save()


def reverse_migrate_country_config_data(apps, schema_editor):
    """Reverse migration: recreate CountryConfig from Country data"""
    Country = apps.get_model('common', 'Country')
    CountryConfig = apps.get_model('common', 'CountryConfig')
    
    for country in Country.objects.all():
        CountryConfig.objects.create(
            country=country,
            payment_methods=country.payment_methods,
            exchange_rate_to_base=country.exchange_rate_to_base,
            is_active=country.is_active
        )


class Migration(migrations.Migration):

    dependencies = [
        ('common', '0008_systemconfiguration_app_update_url_and_more'),
    ]

    operations = [
        # Add payment fields to Country
        migrations.AddField(
            model_name='country',
            name='exchange_rate_to_base',
            field=models.DecimalField(decimal_places=4, default=1.0, help_text='Exchange rate from base currency (UGX) to this country\'s currency', max_digits=10),
        ),
        migrations.AddField(
            model_name='country',
            name='payment_methods',
            field=models.JSONField(default=list, help_text='Available payment methods: [\'wallet\', \'pesapal\', \'mpesa\', \'flutterwave\', \'paystack\', \'stripe\']'),
        ),
        # Migrate data from CountryConfig to Country
        migrations.RunPython(
            migrate_country_config_data,
            reverse_code=reverse_migrate_country_config_data
        ),
        # Remove CountryConfig model
        migrations.DeleteModel(
            name='CountryConfig',
        ),
    ]