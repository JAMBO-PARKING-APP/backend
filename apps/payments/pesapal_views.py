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
from apps.parking.models import ParkingSession, Reservation

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

        # Optional: Link to parking session or reservation
        parking_session = None
        reservation = None
        
        if session_id:
            try:
                parking_session = ParkingSession.objects.get(id=session_id)
            except ParkingSession.DoesNotExist:
                pass
                
        reservation_id = request.data.get('reservation_id')
        if reservation_id:
            try:
                reservation = Reservation.objects.get(id=reservation_id)
            except Reservation.DoesNotExist:
                pass

        # Create Transaction record
        transaction = Transaction.objects.create(
            user=request.user,
            amount=Decimal(amount),
            pesapal_merchant_reference=merchant_reference,
            status=TransactionStatus.PENDING,
            parking_session=parking_session,
            reservation=reservation,
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

        if response and response.get('redirect_url'):
            # API 3.0 returns 'redirect_url', 'order_tracking_id', 'merchant_reference'
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
                if transaction.parking_session:
                    # Activate the parking session
                    session = transaction.parking_session
                    if session.status == 'pending_payment': # Use string if constant not imported, or import it
                        session.status = 'active'
                        # Refresh planned_end_time? Optional, but let's keep original for now.
                        session.save()
                        
                        # Send notifications
                        from apps.notifications.notification_triggers import notify_parking_started, notify_payment_success
                        notify_payment_success(transaction)
                        notify_parking_started(session)
                        
            elif payment_status == "Failed":
                transaction.status = TransactionStatus.FAILED
            
            transaction.processor_response = status_response
            transaction.save()

            # For a mobile app callback, we usually want to show a success/failure page
            # or redirect to a custom scheme.
            # providing a simple HTML response for now.
            return Response({
                'status': 'success',
                'payment_status': payment_status, 
                'merchant_reference': merchant_reference
            })

        except Transaction.DoesNotExist:
            logger.error(f"Transaction with reference {merchant_reference} not found")
            return Response({'error': 'Transaction not found'}, status=status.HTTP_404_NOT_FOUND)

class PesapalIPNView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        """Handle IPN POST request"""
        data = request.data
        return self.process_ipn(data)

    def get(self, request):
        """Handle IPN GET request"""
        data = request.query_params
        return self.process_ipn(data)

    def process_ipn(self, data):
        order_tracking_id = data.get('OrderTrackingId')
        merchant_reference = data.get('OrderMerchantReference')
        notification_type = data.get('OrderNotificationType')

        if not order_tracking_id:
             return Response({'error': 'Missing OrderTrackingId'}, status=status.HTTP_400_BAD_REQUEST)

        pesapal = PesapalService()
        status_response = pesapal.get_transaction_status(order_tracking_id)
        
        if not status_response:
             # If we can't verify, we should probably return 500 so Pesapal retries
             return Response({'error': 'Verification failed'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        try:
            transaction = Transaction.objects.get(pesapal_merchant_reference=merchant_reference)
            payment_status = status_response.get('payment_status_description')
            
            if payment_status == "Completed":
                transaction.status = TransactionStatus.COMPLETED
                if transaction.parking_session:
                    # Activate the parking session
                    session = transaction.parking_session
                    if session.status == 'pending_payment':
                        session.status = 'active'
                        session.save()
                        
                        # Send notifications
                        from apps.notifications.notification_triggers import notify_parking_started, notify_payment_success
                        notify_payment_success(transaction)
                        notify_parking_started(session)

            elif payment_status == "Failed":
                transaction.status = TransactionStatus.FAILED
                
            transaction.processor_response = status_response
            transaction.save()
            
            # Respond to Pesapal as required
            response_data = {
                "orderNotificationType": notification_type,
                "orderTrackingId": order_tracking_id,
                "orderMerchantReference": merchant_reference,
                "status": 200
            }
            return Response(response_data)

        except Transaction.DoesNotExist:
             logger.error(f"IPN: Transaction {merchant_reference} not found")
             return Response({'error': 'Transaction not found'}, status=status.HTTP_404_NOT_FOUND)
