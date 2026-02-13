from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.common.models import BaseModel

class LoyaltyAccount(BaseModel):
    user = models.OneToOneField('accounts.User', on_delete=models.CASCADE, related_name='loyalty_account')
    balance = models.IntegerField(default=0, help_text=_("Current redeemable points"))
    lifetime_points = models.IntegerField(default=0, help_text=_("Total points earned ever (for tiers)"))
    tier = models.CharField(max_length=20, default='Bronze', choices=[
        ('Bronze', 'Bronze'),
        ('Silver', 'Silver'), 
        ('Gold', 'Gold'),
        ('Platinum', 'Platinum')
    ])

    class Meta:
        indexes = [
            models.Index(fields=['user'], name='rwd_loy_usr_idx'),
            models.Index(fields=['tier'], name='rwd_loy_tier_idx'),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.balance} pts ({self.tier})"

class PointTransaction(BaseModel):
    TRANSACTION_TYPES = [
        ('earned', _('Earned')),
        ('redeemed', _('Redeemed')),
        ('expired', _('Expired')),
        ('bonus', _('Bonus')),
    ]

    account = models.ForeignKey(LoyaltyAccount, on_delete=models.CASCADE, related_name='transactions')
    amount = models.IntegerField()
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    description = models.CharField(max_length=255)
    reference_id = models.CharField(max_length=100, blank=True, null=True, help_text=_("Related ID (e.g. Session ID)"))

    class Meta:
        indexes = [
            models.Index(fields=['account'], name='rwd_ptx_acc_idx'),
            models.Index(fields=['transaction_type'], name='rwd_ptx_type_idx'),
            models.Index(fields=['created_at'], name='rwd_ptx_cr_idx'),
            models.Index(fields=['account', 'created_at'], name='rwd_ptx_acc_cr_idx'),
        ]
    
    def __str__(self):
        return f"{self.account.user.email} - {self.transaction_type} {self.amount}"
