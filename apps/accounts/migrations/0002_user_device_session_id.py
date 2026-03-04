# Generated migration for adding device_session_id field

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='device_session_id',
            field=models.FloatField(default=0, help_text='Timestamp of last login - used for single device login', verbose_name='Device Session ID'),
        ),
    ]
