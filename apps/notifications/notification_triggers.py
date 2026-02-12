"""
Notification Trigger Functions

Helper functions to create and send notifications for common events
in the parking system (parking sessions, payments, violations, etc.)
"""

import logging
from django.utils import timezone
from .models import NotificationEvent
from .firebase_service import send_notification_to_user

logger = logging.getLogger(__name__)


def notify_parking_started(session):
    """
    Notify user that parking session has started
    
    Args:
        session: ParkingSession instance
    """
    user = session.vehicle.user
    
    title = "Parking Session Started"
    message = f"Your parking at {session.zone.name} has started. Session ends at {session.planned_end_time.strftime('%I:%M %p')}"
    
    notification = NotificationEvent.objects.create(
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
            'show_dialog': 'true',  # Flag to show in-app dialog
        },
        notification_event=notification
    )
    
    logger.info(f"Sent parking started notification to user {user.id} for session {session.id}")


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
    
    # Create notification event
    notification = NotificationEvent.objects.create(
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
    
    # Send push notification
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'parking_expiring',
            'session_id': str(session.id),
            'zone_id': str(session.zone.id),
            'minutes_remaining': str(minutes_remaining),
            'show_dialog': 'true',  # Flag to show in-app dialog
        },
        notification_event=notification
    )
    
    logger.info(f"Sent parking expiring notification to user {user.id} for session {session.id}")


def notify_parking_ended(session):
    """
    Notify user that their parking session has ended
    
    Args:
        session: ParkingSession instance
    """
    user = session.vehicle.user
    
    title = "Parking Session Ended"
    message = f"Your parking session at {session.zone.name} has ended. Total cost: UGX {session.final_cost}"
    
    notification = NotificationEvent.objects.create(
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
            'show_dialog': 'true',  # Flag to show in-app dialog
        },
        notification_event=notification
    )
    
    logger.info(f"Sent parking ended notification to user {user.id} for session {session.id}")


def notify_payment_success(payment):
    """
    Notify user of successful payment
    
    Args:
        payment: Transaction or WalletTransaction instance
    """
    # Handle both Transaction and WalletTransaction
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
    
    title = "Payment Successful"
    message = f"Your payment of UGX {amount} was successful."
    
    notification = NotificationEvent.objects.create(
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
            'show_dialog': 'true',  # Flag to show in-app dialog
        },
        notification_event=notification
    )
    
    logger.info(f"Sent payment success notification to user {user.id} for payment {payment_id}")


def notify_payment_failed(payment, reason: str = ""):
    """
    Notify user of failed payment
    
    Args:
        payment: Payment instance
        reason: Reason for payment failure
    """
    user = payment.user
    
    title = "Payment Failed"
    message = f"Your payment of UGX {payment.amount} failed."
    if reason:
        message += f" Reason: {reason}"
    
    notification = NotificationEvent.objects.create(
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
    
    logger.info(f"Sent payment failed notification to user {user.id} for payment {payment.id}")


def notify_violation_issued(violation):
    """
    Notify user that a violation has been issued
    
    Args:
        violation: Violation instance
    """
    user = violation.vehicle.user
    
    title = "Parking Violation Issued"
    message = f"A parking violation has been issued for {violation.vehicle.license_plate}. Fine: UGX {violation.fine_amount}"
    
    notification = NotificationEvent.objects.create(
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
    
    logger.info(f"Sent violation notification to user {user.id} for violation {violation.id}")


def notify_custom(user, title: str, message: str, category: str = 'system', data: dict = None):
    """
    Send a custom notification to a user
    
    Args:
        user: User instance
        title: Notification title
        message: Notification message
        category: Notification category
        data: Optional custom data dictionary
    """
    notification = NotificationEvent.objects.create(
        user=user,
        title=title,
        message=message,
        type='other',
        category=category,
        metadata=data or {}
    )
    
    send_notification_to_user(
        user=user,
        title=title,
        body=message,
        data={
            'type': 'custom',
            **(data or {})
        },
        notification_event=notification
    )
    
    logger.info(f"Sent custom notification to user {user.id}")


def notify_officer_zone_assignment(officer, zone):
    """
    Notify officer of zone assignment
    
    Args:
        officer: User instance (officer)
        zone: Zone instance
    """
    title = "Zone Assignment"
    message = f"You have been assigned to monitor {zone.name}."
    
    notification = NotificationEvent.objects.create(
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


def notify_wallet_refund(wallet_transaction, parking_session):
    """
    Notify user of wallet refund for early session end
    
    Args:
        wallet_transaction: WalletTransaction instance
        parking_session: ParkingSession instance
    """
    user = wallet_transaction.user
    
    title = "Wallet Refund"
    message = f"You've been refunded UGX {wallet_transaction.amount} for ending your parking session early at {parking_session.zone.name}."
    
    notification = NotificationEvent.objects.create(
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
            'show_dialog': 'true',  # Flag to show in-app dialog
        },
        notification_event=notification
    )
    
    logger.info(f"Sent wallet refund notification to user {user.id} for {wallet_transaction.amount}")
