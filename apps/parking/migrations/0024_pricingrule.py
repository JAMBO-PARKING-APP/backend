# Generated manually for PricingRule model

from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('parking', '0023_zoneapplication_zone_picture'),
    ]

    operations = [
        migrations.CreateModel(
            name='PricingRule',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('country', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='common.country')),
                ('rule_type', models.CharField(choices=[('time_based', 'Time Based'), ('demand_based', 'Demand Based'), ('special_event', 'Special Event')], max_length=20)),
                ('name', models.CharField(help_text='Descriptive name for this pricing rule', max_length=100)),
                ('description', models.TextField(blank=True, help_text='Optional description of when this rule applies')),
                ('hourly_rate', models.DecimalField(decimal_places=2, help_text='Rate to apply when this rule is active', max_digits=12)),
                ('is_active', models.BooleanField(default=True, help_text='Whether this rule is currently active')),
                ('priority', models.IntegerField(default=0, help_text='Higher priority rules override lower ones (0-100)')),
                ('zone', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='pricing_rules', to='parking.zone')),
            ],
            options={
                'ordering': ['-priority', '-created_at'],
                'abstract': False,
            },
        ),
        migrations.CreateModel(
            name='TimeBasedPricingRule',
            fields=[
                ('pricingrule_ptr', models.OneToOneField(auto_created=True, on_delete=django.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='parking.pricingrule')),
                ('start_time', models.TimeField(help_text='Start time for this rate (HH:MM format)')),
                ('end_time', models.TimeField(help_text='End time for this rate (HH:MM format)')),
                ('days_of_week', models.JSONField(default=list, help_text='List of days this rule applies (0=Monday, 6=Sunday)')),
            ],
            options={
                'abstract': False,
            },
            bases=('parking.pricingrule',),
        ),
        migrations.CreateModel(
            name='SpecialEventPricingRule',
            fields=[
                ('pricingrule_ptr', models.OneToOneField(auto_created=True, on_delete=django.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='parking.pricingrule')),
                ('event_date', models.DateField(help_text='Date of the special event')),
                ('start_time', models.TimeField(help_text='Start time of the event')),
                ('end_time', models.TimeField(help_text='End time of the event')),
                ('event_name', models.CharField(help_text='Name of the special event', max_length=200)),
            ],
            options={
                'abstract': False,
            },
            bases=('parking.pricingrule',),
        ),
        migrations.CreateModel(
            name='DemandBasedPricingRule',
            fields=[
                ('pricingrule_ptr', models.OneToOneField(auto_created=True, on_delete=django.db.models.deletion.CASCADE, parent_link=True, primary_key=True, serialize=False, to='parking.pricingrule')),
                ('occupancy_threshold', models.DecimalField(decimal_places=2, help_text='Occupancy percentage threshold (0-100)', max_digits=5)),
                ('price_multiplier', models.DecimalField(decimal_places=2, help_text='Multiplier to apply to base rate (e.g., 1.5 for 50% increase)', max_digits=4)),
            ],
            options={
                'abstract': False,
            },
            bases=('parking.pricingrule',),
        ),
        migrations.AddIndex(
            model_name='pricingrule',
            index=models.Index(fields=['zone', 'rule_type', 'is_active'], name='parking_pric_zone_id_8b8b8b_idx'),
        ),
        migrations.AddIndex(
            model_name='pricingrule',
            index=models.Index(fields=['zone', 'priority'], name='parking_pric_zone_id_9c9c9c_idx'),
        ),
    ]