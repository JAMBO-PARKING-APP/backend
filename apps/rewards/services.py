from django.db import transaction
from django.conf import settings
from .models import LoyaltyAccount, PointTransaction

class LoyaltyService:
    POINTS_PER_UNIT_CURRENCY = 1.0  
    
    @staticmethod
    def get_or_create_account(user):
        account, created = LoyaltyAccount.objects.get_or_create(user=user)
        return account

    @staticmethod
    @transaction.atomic
    def award_points(user, amount_spent, description, reference_id=None):
        """
        Award points based on amount spent.
        """
        if amount_spent <= 0:
            return 0
            
        points_to_award = int(float(amount_spent) * LoyaltyService.POINTS_PER_UNIT_CURRENCY)
        if points_to_award == 0:
            return 0
            
        account = LoyaltyService.get_or_create_account(user)
        
        account.balance += points_to_award
        account.lifetime_points += points_to_award
        
        if account.lifetime_points >= 5000:
            account.tier = 'Platinum'
        elif account.lifetime_points >= 2000:
            account.tier = 'Gold'
        elif account.lifetime_points >= 500:
            account.tier = 'Silver'
            
        account.save()
        
        PointTransaction.objects.create(
            account=account,
            amount=points_to_award,
            transaction_type='earned',
            description=description,
            reference_id=reference_id
        )
        
        return points_to_award

    @staticmethod
    def get_balance(user):
        try:
            return user.loyalty_account.balance
        except LoyaltyAccount.DoesNotExist:
            return 0
