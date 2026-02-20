import json
from decimal import Decimal
from django.db import transaction
from apps.parking.models import ParkingSession
from apps.common.constants import TransactionStatus
from .models import Transaction, PaymentMethod

class PaymentService:
    @staticmethod
    @transaction.atomic
    def initialize_payment(user, session_id, payment_method_id, idempotency_key):
        """Initialize payment for a parking session"""
        
        existing_transaction = Transaction.objects.filter(idempotency_key=idempotency_key).first()
        if existing_transaction:
            return {'transaction_id': existing_transaction.id, 'status': existing_transaction.status}
        
        parking_session = ParkingSession.objects.get(
            id=session_id,
            vehicle__user=user
        )
        
        payment_method = PaymentMethod.objects.get(
            id=payment_method_id,
            user=user,
            is_active=True
        )
        
        amount = parking_session.calculate_cost()
        
        transaction_record = Transaction.objects.create(
            user=user,
            parking_session=parking_session,
            amount=amount,
            payment_method=payment_method,
            idempotency_key=idempotency_key,
            status=TransactionStatus.PENDING
        )
        
        transaction_record.status = TransactionStatus.COMPLETED
        transaction_record.save()
        from apps.notifications.notification_triggers import notify_payment_success
        notify_payment_success(transaction_record)
        
        return {
            'transaction_id': transaction_record.id,
            'amount': amount,
            'status': transaction_record.status
        }
    
    @staticmethod
    def process_webhook(payload, signature):
        """Process webhook from payment processor"""
        pass
    
    @staticmethod
    @transaction.atomic
    def process_refund(transaction_id, amount, reason):
        """Process refund for a transaction"""
        original_transaction = Transaction.objects.get(
            id=transaction_id,
            status=TransactionStatus.COMPLETED
        )
        
        from .models import Refund
        refund = Refund.objects.create(
            original_transaction=original_transaction,
            amount=amount,
            reason=reason,
            status=TransactionStatus.COMPLETED
        )
        
        from apps.notifications.notification_triggers import notify_payment_refund
        notify_payment_refund(refund)
        
        return refund