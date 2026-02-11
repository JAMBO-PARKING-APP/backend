from django.db import migrations, models
from django.contrib.postgres.indexes import GinIndex


class Migration(migrations.Migration):

    dependencies = [
        ('notifications', '0005_rename_notifications_user_id_status_idx_notificatio_user_id_042c0e_idx_and_more'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='notificationevent',
            index=models.Index(fields=['user_id', 'is_read', '-created_at'], name='notification_user_read_created_idx'),
        ),
        migrations.AddIndex(
            model_name='notificationevent',
            index=GinIndex(fields=['metadata'], name='notification_metadata_gin'),
        ),
    ]
