import logging
import uuid
from django.shortcuts import redirect
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from decimal import Decimal

from .pesapal_service import PesapalService
from .models import Transaction
from apps.common.constants import TransactionStatus
from apps.parking.models import ParkingSession

logger = logging.getLogger(__name__)

class PesapalInitPaymentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        amount = request.data.get('amount')
        session_id = request.data.get('session_id')
        currency = request.data.get('currency', 'UGX')
        description = request.data.get('description', 'Parking Payment')

        if not amount:
            return Response({'error': 'Amount is required'}, status=status.HTTP_400_BAD_REQUEST)

        # Generate unique merchant reference
        merchant_reference = str(uuid.uuid4())

        # Optional: Link to parking session
        parking_session = None
        if session_id:
            try:
                parking_session = ParkingSession.objects.get(id=session_id)
            except ParkingSession.DoesNotExist:
                pass

        # Create Transaction record
        transaction = Transaction.objects.create(
            user=request.user,
            amount=Decimal(amount),
            pesapal_merchant_reference=merchant_reference,
            status=TransactionStatus.PENDING,
            parking_session=parking_session,
            idempotency_key=merchant_reference # Using merchant_ref as idempotency key
        )

        pesapal = PesapalService()
        response = pesapal.create_payment(
            amount=amount,
            merchant_reference=merchant_reference,
            description=description,
            user=request.user,
            currency=currency
        )

        if response and response.get('order_tracking_id'):
            transaction.pesapal_order_tracking_id = response.get('order_tracking_id')
            transaction.processor_response = response
            transaction.save()
            
            return Response({
                'redirect_url': response.get('redirect_url'),
                'order_tracking_id': response.get('order_tracking_id'),
                'merchant_reference': merchant_reference
            })
        else:
            transaction.status = TransactionStatus.FAILED
            transaction.save()
            return Response({'error': 'Failed to initiate Pesapal payment'}, status=status.HTTP_400_BAD_REQUEST)

class PesapalCallbackView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        order_tracking_id = request.query_params.get('OrderTrackingId')
        merchant_reference = request.query_params.get('OrderMerchantReference')

        if not order_tracking_id:
            return Response({'error': 'OrderTrackingId is required'}, status=status.HTTP_400_BAD_REQUEST)

        pesapal = PesapalService()
        status_response = pesapal.get_transaction_status(order_tracking_id)

        if not status_response:
            return Response({'error': 'Could not verify payment status'}, status=status.HTTP_400_BAD_REQUEST)

        # Update transaction status
        try:
            transaction = Transaction.objects.get(pesapal_merchant_reference=merchant_reference)
            
            payment_status = status_response.get('payment_status_description')
            
            if payment_status == "Completed":
                transaction.status = TransactionStatus.COMPLETED
                # If linked to a parking session, we might want to update session status too
                if transaction.parking_session:
                    # Logic to mark session as paid if applicable
                    pass
            elif payment_status == "Failed":
                transaction.status = TransactionStatus.FAILED
            
            transaction.processor_response = status_response
            transaction.save()

            logger.info(f"Transaction {merchant_reference} updated to {transaction.status}")
            return Response({'status': transaction.status, 'payment_status': payment_status})

        except Transaction.DoesNotExist:
            logger.error(f"Transaction with reference {merchant_reference} not found")
            return Response({'error': 'Transaction not found'}, status=status.HTTP_404_NOT_FOUND)
