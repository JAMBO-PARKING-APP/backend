from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('enforcement', '0004_officerstatus_qrcodescan_alter_officerlog_options_and_more'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='violation',
            index=models.Index(fields=['vehicle_id', 'is_paid'], name='violation_vehicle_paid_idx'),
        ),
        migrations.AddIndex(
            model_name='violation',
            index=models.Index(fields=['zone_id', 'paid_at'], name='violation_zone_paidat_idx'),
        ),
    ]
