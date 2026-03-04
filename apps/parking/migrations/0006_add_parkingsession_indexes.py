# Generated migration for ParkingSession indexes (performance optimization)

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('parking', '0005_alter_parkingsession_estimated_cost_and_more'),
    ]

    operations = [
        # ParkingSession model indexes
        migrations.AddIndex(
            model_name='parkingsession',
            index=models.Index(fields=['vehicle_id', 'status'], name='parking_session_vehicle_status_idx'),
        ),
        migrations.AddIndex(
            model_name='parkingsession',
            index=models.Index(fields=['status', 'start_time'], name='parking_session_status_time_idx'),
        ),
        migrations.AddIndex(
            model_name='parkingsession',
            index=models.Index(fields=['zone_id', 'status'], name='parking_session_zone_status_idx'),
        ),
    ]
