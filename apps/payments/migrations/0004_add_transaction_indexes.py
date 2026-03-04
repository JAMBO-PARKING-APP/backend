# Generated migration for Transaction indexes (performance optimization)

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0003_alter_refund_amount_alter_transaction_amount_and_more'),
    ]

    operations = [
        # Transaction model indexes
        migrations.AddIndex(
            model_name='transaction',
            index=models.Index(fields=['user_id', 'status', 'created_at'], name='payments_transaction_user_compound_idx'),
        ),
        migrations.AddIndex(
            model_name='transaction',
            index=models.Index(fields=['status', 'created_at'], name='payments_transaction_status_time_idx'),
        ),
        
        # WalletTransaction model indexes
        migrations.AddIndex(
            model_name='wallettransaction',
            index=models.Index(fields=['user_id', 'transaction_type', 'created_at'], name='payments_wallet_user_type_idx'),
        ),
        migrations.AddIndex(
            model_name='wallettransaction',
            index=models.Index(fields=['status', 'created_at'], name='payments_wallet_status_time_idx'),
        ),
    ]
