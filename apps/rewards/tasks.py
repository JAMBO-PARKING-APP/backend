from celery import shared_task
import logging
from apps.accounts.models import User
from .services import LoyaltyService

logger = logging.getLogger(__name__)

@shared_task(name='apps.rewards.tasks.award_loyalty_points_task')
def award_loyalty_points_task(user_id, amount_spent, description, reference_id=None):
    """
    Background task to award loyalty points.
    """
    try:
        user = User.objects.get(id=user_id)
        points = LoyaltyService.award_points(
            user=user,
            amount_spent=amount_spent,
            description=description,
            reference_id=reference_id
        )
        logger.info(f"Awarded {points} points to user {user.phone} for {description}")
        return points
    except User.DoesNotExist:
        logger.error(f"User {user_id} not found for loyalty awarding")
    except Exception as e:
        logger.error(f"Error awarding points in task: {e}")
    return 0
