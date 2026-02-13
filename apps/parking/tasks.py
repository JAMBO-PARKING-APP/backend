from celery import shared_task
from django.utils import timezone
from apps.parking.models import Reservation
import logging

logger = logging.getLogger(__name__)

@shared_task
def expire_reservation_task(reservation_id):
    try:
        reservation = Reservation.objects.get(id=reservation_id)
        if reservation.status == 'pending_payment':
            reservation.status = 'expired'
            reservation.save()
            logger.info(f"Expired unpaid reservation {reservation_id}")
    except Reservation.DoesNotExist:
        logger.warning(f"Reservation {reservation_id} not found during expiration task")
