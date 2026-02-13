from django.core.management.base import BaseCommand
from apps.accounts.models import User
from apps.rewards.services import LoyaltyService
from apps.rewards.models import LoyaltyAccount

class Command(BaseCommand):
    help = 'Verify LoyaltyService Logic'

    def handle(self, *args, **kwargs):
        self.stdout.write("Running LoyaltyService Verification...")
        
        # Setup Data
        user, _ = User.objects.get_or_create(
            email='test_rewards@example.com', 
            defaults={
                'first_name': 'Test', 
                'password': 'pass',
                'phone': '+256700000001'
            }
        )
        
        # Reset
        LoyaltyAccount.objects.filter(user=user).delete()

        # 1. Award Points
        self.stdout.write("1. Awarding points for parking...")
        points = LoyaltyService.award_points(user, 5000, "Test Parking") # 5000 UGX = 50 pts
        
        account = LoyaltyService.get_or_create_account(user)
        self.stdout.write(f"Points awarded: {points}")
        self.stdout.write(f"Current Balance: {account.balance}")
        self.stdout.write(f"Lifetime Points: {account.lifetime_points}")
        self.stdout.write(f"Tier: {account.tier}")
        
        if points == 50 and account.balance == 50:
             self.stdout.write(self.style.SUCCESS("SUCCESS: Points awarded correctly"))
        else:
             self.stdout.write(self.style.ERROR("FAILED: Incorrect point calculation"))

        # 2. Check Tier Upgrade
        self.stdout.write("2. Testing Tier Upgrade...")
        LoyaltyService.award_points(user, 50000, "Bulk Parking") # 500 pts -> Total 550 -> Silver
        account.refresh_from_db()
        self.stdout.write(f"New Lifetime Points: {account.lifetime_points}")
        self.stdout.write(f"New Tier: {account.tier}")
        
        if account.tier == 'Silver':
             self.stdout.write(self.style.SUCCESS("SUCCESS: Tier upgraded to Silver"))
        else:
             self.stdout.write(self.style.ERROR(f"FAILED: Tier not upgraded (Expected Silver, got {account.tier})"))
