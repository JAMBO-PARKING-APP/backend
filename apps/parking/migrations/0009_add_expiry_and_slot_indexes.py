from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('parking', '0008_alter_zone_options'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='parkingsession',
            index=models.Index(fields=['status', 'planned_end_time'], name='parkingsession_status_planned_idx'),
        ),
        migrations.AddIndex(
            model_name='parkingslot',
            index=models.Index(fields=['zone_id', 'status'], name='parkingslot_zone_status_idx'),
        ),
    ]
