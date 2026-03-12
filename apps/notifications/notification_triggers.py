"""
Notification Trigger Functions

Helper functions to create and send notifications for common events
in the parking system (parking sessions, payments, violations, etc.)
"""

import logging
import json
from django.utils import timezone
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from .models import NotificationEvent
from .firebase_service import send_notification_to_user
from apps.common.utils import get_user_local_time

logger = logging.getLogger(__name__)

def _safe_orm_operation(func, *args, **kwargs):
    """Helper to perform ORM operations in a way that handles async contexts"""
    import os
    os.environ["DJANGO_ALLOW_ASYNC_UNSAFE"] = "true"
    try:
        return func(*args, **kwargs)
    finally:
        pass

def broadcast_parking_update(user, data):
    """
    Broadcast a parking update to the user via WebSocket (Asynchronous)
    """
    from .tasks import broadcast_websocket_update_task
    from django.db import transaction
    
    transaction.on_commit(lambda: broadcast_websocket_update_task.delay(
        str(user.id), data
    ))
    logger.debug(f"Scheduled WebSocket broadcast task for user {user.id}")


def notify_parking_started(session):
    """
    Notify user that parking session has started
    
    Args:
        session: ParkingSession instance
    """
    user = session.vehicle.user
    local_end_time = get_user_local_time(user, session.planned_end_time)
    
    title = "Parking Session Started"
    message = f"Your parking at {session.zone.name} has started. Session ends at {local_end_time.strftime('%I:%M %p')}"
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='parking_started',
        category='parking',
        metadata={
            'session_id': str(session.id),
            'zone_id': str(session.zone.id),
            'zone_name': session.zone.name,
            'slot_code': session.parking_slot.slot_code if session.parking_slot else None,
            'planned_end_time': session.planned_end_time.isoformat(),
            'estimated_cost': str(session.estimated_cost),
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'parking_started',
            'session_id': str(session.id),
            'zone_id': str(session.zone.id),
            'slot_code': session.parking_slot.slot_code if session.parking_slot else '',
            'show_dialog': 'true',  
        },
        notification_event=notification
    )
    
    logger.info(f"Sent parking started notification to user {user.id} for session {session.id}")
    broadcast_parking_update(user, {
        'type': 'parking_started',
        'event': 'parking_started',
        'session_id': str(session.id),
        'status': session.status,
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })

def notify_parking_extended(session, additional_hours, cost):
    """
    Notify user that their parking session has been extended
    """
    user = session.vehicle.user
    symbol = getattr(user.country, 'currency_symbol', 'UGX') if hasattr(user, 'country') else 'UGX'
    local_end_time = get_user_local_time(user, session.planned_end_time)
    
    title = "Parking Extended"
    message = f"Your parking at {session.zone.name} was extended by {additional_hours} hours. Cost: {symbol} {cost}. New end time: {local_end_time.strftime('%I:%M %p')}"
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='parking_started', # Reusing parking_started type for UI tracking if needed
        category='parking',
        metadata={
            'session_id': str(session.id),
            'additional_hours': additional_hours,
            'cost': str(cost),
            'new_end_time': session.planned_end_time.isoformat(),
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'parking_extended',
            'session_id': str(session.id),
            'show_dialog': 'true',
        },
        notification_event=notification
    )
    
    broadcast_parking_update(user, {
        'type': 'parking_extended',
        'event': 'parking_extended',
        'session_id': str(session.id),
        'title': title,
        'message': message,
    })
    
    logger.info(f"Sent parking extended notification to user {user.id}")


def notify_parking_expiring_soon(session, minutes_remaining: int):
    """
    Notify user that their parking session is expiring soon
    
    Args:
        session: ParkingSession instance
        minutes_remaining: Minutes until session expires
    """
    user = session.vehicle.user
    
    title = "Parking Expiring Soon"
    message = f"Your parking session at {session.zone.name} expires in {minutes_remaining} minutes."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='parking_ended',
        category='parking',
        metadata={
            'session_id': str(session.id),
            'zone_id': str(session.zone.id),
            'zone_name': session.zone.name,
            'minutes_remaining': minutes_remaining,
            'expiry_time': session.planned_end_time.isoformat(),
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'parking_expiring',
            'session_id': str(session.id),
            'zone_id': str(session.zone.id),
            'minutes_remaining': str(minutes_remaining),
            'show_dialog': 'true', 
        },
        notification_event=notification
    )
    
    broadcast_parking_update(user, {
        'type': 'parking_expiring',
        'event': 'parking_expiring',
        'session_id': str(session.id),
        'minutes_remaining': minutes_remaining,
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })
    
    logger.info(f"Sent parking expiring notification to user {user.id} for session {session.id}")


def notify_parking_ended(session):
    """
    Notify user that their parking session has ended (Asynchronous)
    """
    from .tasks import notify_parking_ended_task
    from django.db import transaction
    
    transaction.on_commit(lambda: notify_parking_ended_task.delay(str(session.id)))
    logger.info(f"Scheduled parking ended notification task for session {session.id}")

def notify_parking_ended_sync(session):
    """
    The actual synchronous logic for parking ended notifications
    (Called by Celery task)
    """
    user = session.vehicle.user
    
    is_expired = session.status == 'expired' or (session.planned_end_time and timezone.now() > session.planned_end_time)
    symbol = getattr(user.country, 'currency_symbol', 'UGX') if hasattr(user, 'country') else 'UGX'
    
    if is_expired:
        title = "Parking Session Expired"
        message = f"Your parking session in {session.zone.name} has ended and the time has run out. Please leave the parking zone immediately to avoid further charges or violations. Total cost: {symbol} {session.final_cost}"
    else:
        title = "Parking Session Ended"
        message = f"Your parking session at {session.zone.name} has ended. Total cost: {symbol} {session.final_cost}"
    
    from apps.accounts.models import UserLocation
    from apps.common.utils import calculate_distance
    
    last_location = UserLocation.objects.filter(user=user).order_by('-timestamp').first()
    if last_location:
        distance = calculate_distance(
            last_location.latitude, last_location.longitude,
            session.zone.latitude, session.zone.longitude
        )
        
        if distance <= (session.zone.radius_meters + 20):
            message += " Our system indicates you are still in the parking zone. Please vacate the spot now to avoid enforcement actions."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='parking_ended',
        category='parking',
        metadata={
            'session_id': str(session.id),
            'zone_id': str(session.zone.id),
            'zone_name': session.zone.name,
            'final_cost': str(session.final_cost),
            'duration_minutes': session.duration_minutes,
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'parking_ended',
            'session_id': str(session.id),
            'zone_id': str(session.zone.id),
            'final_cost': str(session.final_cost),
            'show_dialog': 'true',  
        },
        notification_event=notification
    )
    
    channel_layer = get_channel_layer()
    user_group_name = f"user_{user.id}".replace("-", "_")
    async_to_sync(channel_layer.group_send)(
        user_group_name,
        {
            'type': 'parking_update',
            'data': {
                'type': 'parking_ended',
                'event': 'parking_ended',
                'session_id': str(session.id),
                'status': session.status,
                'final_cost': str(session.final_cost),
                'title': title,
                'message': message,
                'show_dialog': 'true',
            }
        }
    )


def notify_payment_success(payment):
    """
    Notify user of successful payment
    
    Args:
        payment: Transaction or WalletTransaction instance
    """
    from apps.payments.models import WalletTransaction
    
    if isinstance(payment, WalletTransaction):
        user = payment.user
        amount = payment.amount
        payment_method = payment.transaction_type
        payment_id = payment.id
    else:
        user = payment.user
        amount = payment.amount
        payment_method = getattr(payment, 'payment_method', 'wallet')
        payment_id = payment.id
    symbol = getattr(user.country, 'currency_symbol', 'UGX') if hasattr(user, 'country') else 'UGX'
    
    title = "Payment Successful"
    message = f"Your payment of {symbol} {amount} was successful."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='payment_successful',
        category='payments',
        metadata={
            'payment_id': str(payment_id),
            'amount': str(amount),
            'payment_method': str(payment_method),
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'payment_success',
            'payment_id': str(payment_id),
            'amount': str(amount),
            'show_dialog': 'true',  
        },
        notification_event=notification
    )
    
    logger.info(f"Sent payment success notification to user {user.id} for payment {payment_id}")

    broadcast_parking_update(user, {
        'type': 'payment_success',
        'event': 'payment_success',
        'payment_id': str(payment_id),
        'amount': str(amount),
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })


def notify_payment_failed(payment, reason: str = ""):
    """
    Notify user of failed payment
    
    Args:
        payment: Payment instance
        reason: Reason for payment failure
    """
    user = payment.user
    symbol = getattr(user.country, 'currency_symbol', 'UGX') if hasattr(user, 'country') else 'UGX'
    
    title = "Payment Failed"
    message = f"Your payment of {symbol} {payment.amount} failed."
    if reason:
        message += f" Reason: {reason}"
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='payment_failed',
        category='payments',
        metadata={
            'payment_id': str(payment.id),
            'amount': str(payment.amount),
            'reason': reason,
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'payment_failed',
            'payment_id': str(payment.id),
            'amount': str(payment.amount),
        },
        notification_event=notification
    )

    broadcast_parking_update(user, {
        'type': 'payment_failed',
        'event': 'payment_failed',
        'payment_id': str(payment.id),
        'amount': str(payment.amount),
        'reason': reason,
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })
    
    logger.info(f"Sent payment failed notification to user {user.id} for payment {payment.id}")


def notify_violation_issued(violation, message: str = ""):
    """
    Notify user that a violation has been issued
    
    Args:
        violation: Violation instance
        message: Optional custom message
    """
    user = violation.vehicle.user
    
    symbol = getattr(user.country, 'currency_symbol', 'UGX') if hasattr(user, 'country') else 'UGX'
    
    title = "Parking Violation Issued"
    if not message:
        message = f"A parking violation has been issued for {violation.vehicle.license_plate}. Fine: {symbol} {violation.fine_amount}"
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='violation_received',
        category='violations',
        metadata={
            'violation_id': str(violation.id),
            'vehicle_id': str(violation.vehicle.id),
            'license_plate': violation.vehicle.license_plate,
            'fine_amount': str(violation.fine_amount),
            'violation_type': violation.violation_type,
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'violation_issued',
            'violation_id': str(violation.id),
            'fine_amount': str(violation.fine_amount),
        },
        notification_event=notification
    )

    broadcast_parking_update(user, {
        'type': 'violation_issued',
        'event': 'violation_issued',
        'violation_id': str(violation.id),
        'fine_amount': str(violation.fine_amount),
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })
    
    logger.info(f"Sent violation notification to user {user.id} for violation {violation.id}")


def notify_overdue_charge(user, amount, hours, session_id):
    """
    Notify user of overdue parking charge deducted from wallet
    """
    symbol = getattr(user.country, 'currency_symbol', 'UGX') if hasattr(user, 'country') else 'UGX'
    
    title = "Overdue Parking Charge"
    message = f"{symbol} {amount} has been deducted from your wallet for {hours:.2f} hours of overdue parking."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='payment_successful',
        category='payments',
        metadata={
            'parking_session_id': str(session_id),
            'amount': str(amount),
            'hours': float(hours)
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'overdue_charge',
            'amount': str(amount),
            'show_dialog': 'true',
        },
        notification_event=notification
    )
    
    broadcast_parking_update(user, {
        'type': 'payment_success',
        'event': 'overdue_charge',
        'amount': str(amount),
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })
    
    logger.info(f"Sent overdue charge notification to user {user.id}")


    logger.info(f"Sent overdue charge notification to user {user.id}")


def notify_session_reminder(session):
    """
    Notify user that they are far from their active parking session
    """
    user = session.vehicle.user
    title = "Active Parking Session"
    message = f"You seem to be away from {session.zone.name}. Did you forget to end your parking session?"
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='system_alert',
        category='parking',
        metadata={'session_id': str(session.id)}
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={'type': 'session_reminder', 'session_id': str(session.id)},
        notification_event=notification
    )
    
    broadcast_parking_update(user, {
        'event': 'session_reminder',
        'session_id': str(session.id),
        'title': title,
        'message': message
    })


def notify_exit_reminder(session):
    """
    Notify user to exit the zone after session has ended
    """
    user = session.vehicle.user
    title = "Exit Reminder"
    message = f"Your session at {session.zone.name} has ended. Please remember to exit the zone to avoid penalties."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='system_alert',
        category='parking',
        metadata={'session_id': str(session.id)}
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={'type': 'exit_reminder', 'session_id': str(session.id)},
        notification_event=notification
    )
    
    broadcast_parking_update(user, {
        'event': 'exit_reminder',
        'session_id': str(session.id),
        'title': title,
        'message': message
    })


def notify_custom(user, title: str, message: str, category: str = 'system', data: dict = None):
    """
    Send a custom notification to a user
    """
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='custom_admin',
        category=category,
        show_as_dialog=True, 
        metadata=data or {}
    )
    
    notification_data = {
        'type': 'custom_admin',
        'show_dialog': 'true',
        'priority': (data or {}).get('priority', 'medium'),
        **(data or {})
    }

    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data=notification_data,
        notification_event=notification
    )
    
    broadcast_parking_update(user, {
        'type': 'custom_admin',
        'event': 'custom_notification',
        'title': title,
        'message': message,
        **notification_data
    })
    
    logger.info(f"Sent custom notification to user {user.id}")


def notify_campaign(user, title: str, message: str, image_url: str = None, data: dict = None):
    """
    Send a promotional campaign notification to a user
    """
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='promotional_offer',
        category='promo',
        is_promotional=True,
        show_as_dialog=True,
        metadata={
            **(data or {}),
            'image_url': image_url
        }
    )
    
    notification_data = {
        'type': 'campaign',
        'show_dialog': 'true',
        'image_url': image_url or '',
        **(data or {})
    }

    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data=notification_data,
        notification_event=notification
    )
    
    broadcast_parking_update(user, {
        'type': 'campaign',
        'event': 'campaign',
        'title': title,
        'message': message,
        **notification_data
    })
    
    logger.info(f"Sent campaign notification to user {user.id}")


def notify_officer_zone_assignment(officer, zone):
    """
    Notify officer of zone assignment
    
    Args:
        officer: User instance (officer)
        zone: Zone instance
    """
    title = "Zone Assignment"
    message = f"You have been assigned to monitor {zone.name}."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=officer,
        title=title,
        message=message,
        type='system_alert',
        category='system',
        metadata={
            'zone_id': str(zone.id),
            'zone_name': zone.name,
        }
    )
    
    send_notification_to_user(
        user=officer,
        title=title,
        body=message,
        data={
            'type': 'zone_assignment',
            'zone_id': str(zone.id),
        },
        notification_event=notification
    )
    
    logger.info(f"Sent zone assignment notification to officer {officer.id}")


def notify_hotspot_detected(officer, zone, count):
    """
    Notify officer of a violation hotspot
    """
    title = "Violation Hotspot Detected"
    message = f"High violation activity in {zone.name} ({count} potential violations). Please patrol."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=officer,
        title=title,
        message=message,
        type='system_alert',
        category='violations',
        metadata={
            'zone_id': str(zone.id),
            'zone_name': zone.name,
            'count': count
        }
    )
    
    send_notification_to_user(
        officer,
        title=title,
        body=message,
        data={'type': 'officer_dispatch', 'zone_id': str(zone.id)},
        notification_event=notification
    )
    
    broadcast_parking_update(officer, {
        'event': 'officer_dispatch',
        'zone_id': str(zone.id),
        'title': title,
        'message': message
    })


def notify_wallet_refund(wallet_transaction, parking_session):
    """
    Notify user of wallet refund for early session end
    
    Args:
        wallet_transaction: WalletTransaction instance
        parking_session: ParkingSession instance
    """
    user = wallet_transaction.user
    symbol = getattr(user.country, 'currency_symbol', 'UGX') if hasattr(user, 'country') else 'UGX'
    
    title = "Wallet Refund"
    message = f"You've been refunded {symbol} {wallet_transaction.amount} for ending your parking session early at {parking_session.zone.name}."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='wallet_refund',
        category='payments',
        metadata={
            'wallet_transaction_id': str(wallet_transaction.id),
            'session_id': str(parking_session.id),
            'refund_amount': str(wallet_transaction.amount),
            'zone_name': parking_session.zone.name,
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'wallet_refund',
            'wallet_transaction_id': str(wallet_transaction.id),
            'session_id': str(parking_session.id),
            'amount': str(wallet_transaction.amount),
            'show_dialog': 'true', 
        },
        notification_event=notification
    )

    broadcast_parking_update(user, {
        'type': 'wallet_refund',
        'event': 'wallet_refund',
        'wallet_transaction_id': str(wallet_transaction.id),
        'session_id': str(parking_session.id),
        'amount': str(wallet_transaction.amount),
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })
    
    logger.info(f"Sent wallet refund notification to user {user.id} for {wallet_transaction.amount}")


def notify_reservation_confirmed(reservation):
    """
    Notify user of confirmed reservation
    Args: reservation: Reservation instance
    """
    user = reservation.vehicle.user
    local_start_time = get_user_local_time(user, reservation.reserved_from)
    start_time_str = local_start_time.strftime('%b %d, %I:%M %p')
    
    title = "Reservation Confirmed"
    message = f"Your parking reservation at {reservation.zone.name} is confirmed for {start_time_str}."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='reservation_confirmed',
        category='reservations',
        metadata={
            'reservation_id': str(reservation.id),
            'zone_name': reservation.zone.name,
            'start_time': reservation.reserved_from.isoformat(),
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'reservation_confirmed',
            'reservation_id': str(reservation.id),
            'zone_name': reservation.zone.name,
            'show_dialog': 'true',
        },
        notification_event=notification
    )

    broadcast_parking_update(user, {
        'type': 'reservation_confirmed',
        'event': 'reservation_confirmed',
        'reservation_id': str(reservation.id),
        'zone_name': reservation.zone.name,
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })

    logger.info(f"Sent reservation confirmed notification to user {user.id}")


def notify_reservation_cancelled(reservation):
    """
    Notify user of cancelled reservation
    Args: reservation: Reservation instance
    """
    user = reservation.vehicle.user
    
    title = "Reservation Cancelled"
    message = f"Your parking reservation at {reservation.zone.name} has been cancelled."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='reservation_cancelled',
        category='reservations',
        metadata={
            'reservation_id': str(reservation.id),
            'zone_name': reservation.zone.name,
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'reservation_cancelled',
            'reservation_id': str(reservation.id),
            'show_dialog': 'true',
        },
        notification_event=notification
    )

    broadcast_parking_update(user, {
        'type': 'reservation_cancelled',
        'event': 'reservation_cancelled',
        'reservation_id': str(reservation.id),
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })

    logger.info(f"Sent reservation cancelled notification to user {user.id}")


def notify_officers_session_event(session, event_type):
    """
    Notify online officers in the zone about a session event (end or extension)
    
    Args:
        session: ParkingSession instance
        event_type: 'session_ended' or 'session_extended'
    """
    from apps.enforcement.models import OfficerStatus
    
    zone = session.zone
    vehicle = session.vehicle
    
    online_officers = OfficerStatus.objects.filter(
        current_zone=zone,
        is_online=True
    ).select_related('officer')
    
    if not online_officers.exists():
        logger.debug(f"No online officers in zone {zone.name} to notify about {event_type}")
        return
    
    title = "Session Update"
    if event_type == 'session_ended':
        body = f"Session for {vehicle.license_plate} in {zone.name} has ended."
    else:
        body = f"Session for {vehicle.license_plate} in {zone.name} has been extended."
        
    data = {
        'type': event_type,
        'session_id': str(session.id),
        'zone_id': str(zone.id),
        'license_plate': vehicle.license_plate,
        'timestamp': timezone.now().isoformat(),
    }
    
    officer_users = [status.officer for status in online_officers]
    from .firebase_service import send_notification_to_multiple_users
    send_notification_to_multiple_users(officer_users, title, body, data)
    
    logger.info(f"Notified {len(officer_users)} officers about {event_type} for session {session.id}")


def notify_payment_refund(refund):
    """
    Notify user of a payment refund
    """
    user = refund.original_transaction.user
    amount = refund.amount
    symbol = getattr(user.country, 'currency_symbol', 'UGX') if hasattr(user, 'country') else 'UGX'
    
    title = "Refund Processed"
    message = f"A refund of {symbol} {amount} has been processed for your transaction."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='payment_successful',
        category='payments',
        metadata={
            'refund_id': str(refund.id),
            'transaction_id': str(refund.original_transaction.id),
            'amount': str(amount),
            'reason': refund.reason
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'payment_refund',
            'refund_id': str(refund.id),
            'amount': str(amount),
            'show_dialog': 'true',
        },
        notification_event=notification
    )
    
    broadcast_parking_update(user, {
        'type': 'payment_refund',
        'event': 'payment_refund',
        'refund_id': str(refund.id),
        'amount': str(amount),
        'title': title,
        'message': message,
        'show_dialog': 'true',
    })
    
    logger.info(f"Sent payment refund notification to user {user.id}")

def notify_violation_escalation(violation, increase_amount):
    """
    Notify user that their violation fine has increased due to non-payment.
    """
    user = violation.vehicle.user
    symbol = getattr(user.country, 'currency_symbol', 'UGX') if hasattr(user, 'country') else 'UGX'
    
    title = "Violation Fine Escalated"
    message = f"Your fine for violation {violation.id} has increased by {symbol} {increase_amount} due to non-payment. Please pay promptly to avoid further penalties."
    
    notification = _safe_orm_operation(NotificationEvent.objects.create,
        user=user,
        title=title,
        message=message,
        type='violation_issued', 
        category='enforcement',
        metadata={
            'violation_id': str(violation.id),
            'increase_amount': str(increase_amount),
            'current_total': str(violation.fine_amount)
        }
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'violation_escalated',
            'violation_id': str(violation.id),
        },
        notification_event=notification
    )
    
    broadcast_parking_update(user, {
        'type': 'violation_update',
        'event': 'violation_escalated',
        'violation_id': str(violation.id),
        'title': title,
        'message': message
    })
    
    logger.info(f"Sent violation escalation notification to user {user.id}")
