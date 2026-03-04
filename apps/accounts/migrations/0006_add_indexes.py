# Generated migration for database indexes (performance optimization)

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0005_user_wallet_balance'),
    ]

    operations = [
        # User model indexes
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['is_active'], name='accounts_user_is_active_idx'),
        ),
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['phone'], name='accounts_user_phone_idx'),
        ),
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['device_session_id'], name='accounts_device_session_idx'),
        ),
        
        # OTPCode model indexes
        migrations.AddIndex(
            model_name='otpcode',
            index=models.Index(fields=['user_id', 'is_used', 'expires_at'], name='accounts_otp_user_compound_idx'),
        ),
    ]
