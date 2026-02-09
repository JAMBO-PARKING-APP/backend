"""
Payments API Endpoints for User App
- Transaction management
- Payment methods
- Invoices
- Payment history
"""

import uuid
from decimal import Decimal
from django.db import transaction
from rest_framework import generics, status
from rest_framework.decorators import permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Transaction, PaymentMethod, Invoice, WalletTransaction
from .serializers_v2 import (
    TransactionSerializer, PaymentMethodSerializer, InvoiceSerializer,
    TransactionListSerializer, PesapalPaymentSerializer, WalletTransactionSerializer
)
from .pesapal_service import PesapalService
from apps.enforcement.models import Violation
from apps.parking.models import ParkingSession, ParkingStatus

class PaymentMethodsListAPIView(generics.ListAPIView):
    """List user's payment methods"""
    permission_classes = [IsAuthenticated]
    serializer_class = PaymentMethodSerializer
    
    def get_queryset(self):
        return self.request.user.payment_methods.filter(is_active=True)

class SetDefaultPaymentMethodAPIView(APIView):
    """Set a payment method as default"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, pk):
        try:
            payment_method = request.user.payment_methods.get(id=pk, is_active=True)
            
            # Remove default from others
            request.user.payment_methods.exclude(id=pk).update(is_default=False)
            
            # Set this as default
            payment_method.is_default = True
            payment_method.save()
            
            return Response({
                'message': 'Default payment method updated',
                'payment_method': PaymentMethodSerializer(payment_method).data
            }, status=status.HTTP_200_OK)
            
        except PaymentMethod.DoesNotExist:
            return Response({
                'error': 'Payment method not found'
            }, status=status.HTTP_404_NOT_FOUND)

class CreatePaymentAPIView(APIView):
    """Create a payment transaction"""
    permission_classes = [IsAuthenticated]
    
    @transaction.atomic
    def post(self, request):
        amount = request.data.get('amount')
        payment_method_id = request.data.get('payment_method_id')
        parking_session_id = request.data.get('parking_session_id')
        violation_id = request.data.get('violation_id')
        
        if not amount or not payment_method_id:
            return Response({
                'error': 'amount and payment_method_id are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            amount = Decimal(str(amount))
            
            # Validate payment method
            payment_method = request.user.payment_methods.get(
                id=payment_method_id,
                is_active=True
            )
            
            # Validate target (parking session or violation)
            parking_session = None
            if parking_session_id:
                parking_session = ParkingSession.objects.get(
                    id=parking_session_id,
                    vehicle__user=request.user
                )
            
            violation = None
            if violation_id:
                violation = Violation.objects.get(
                    id=violation_id,
                    vehicle__user=request.user
                )
                if violation.is_paid:
                    return Response({
                        'error': 'Violation already paid'
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create transaction
            idempotency_key = str(uuid.uuid4())
            
            trans = Transaction.objects.create(
                user=request.user,
                amount=amount,
                payment_method=payment_method,
                parking_session=parking_session,
                idempotency_key=idempotency_key,
                status='completed'  # In production, integrate with Stripe/payment gateway
            )
            
            # Mark violation as paid if applicable
            if violation:
                violation.is_paid = True
                violation.paid_at = trans.created_at
                violation.save()
            
            # Create invoice
            invoice_number = f"INV-{trans.id:06d}"
            invoice = Invoice.objects.create(
                transaction=trans,
                invoice_number=invoice_number
            )
            
            return Response({
                'message': 'Payment created successfully',
                'transaction': TransactionSerializer(trans).data,
                'invoice': InvoiceSerializer(invoice).data
            }, status=status.HTTP_201_CREATED)
            
        except PaymentMethod.DoesNotExist:
            return Response({
                'error': 'Payment method not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except ParkingSession.DoesNotExist:
            return Response({
                'error': 'Parking session not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Violation.DoesNotExist:
            return Response({
                'error': 'Violation not found'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

class TransactionListAPIView(generics.ListAPIView):
    """List user's transactions"""
    permission_classes = [IsAuthenticated]
    serializer_class = TransactionListSerializer
    
    def get_queryset(self):
        return Transaction.objects.filter(user=self.request.user).order_by('-created_at')

class TransactionDetailAPIView(generics.RetrieveAPIView):
    """Get transaction details"""
    permission_classes = [IsAuthenticated]
    serializer_class = TransactionSerializer
    lookup_field = 'pk'
    
    def get_queryset(self):
        return Transaction.objects.filter(user=self.request.user)

class InvoiceListAPIView(generics.ListAPIView):
    """List user's invoices"""
    permission_classes = [IsAuthenticated]
    serializer_class = InvoiceSerializer
    
    def get_queryset(self):
        return Invoice.objects.filter(transaction__user=self.request.user).order_by('-created_at')

class PaymentSummaryAPIView(APIView):
    """Get payment summary for user"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        from django.db.models import Sum, Count
        
        total_paid = Transaction.objects.filter(
            user=request.user,
            status='completed'
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        pending_amount = Transaction.objects.filter(
            user=request.user,
            status='pending'
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        unpaid_violations = Violation.objects.filter(
            vehicle__user=request.user,
            is_paid=False
        ).aggregate(total=Sum('fine_amount'))['total'] or 0
        
        transaction_count = Transaction.objects.filter(
            user=request.user,
            status='completed'
        ).count()
        
        return Response({
            'total_paid': float(total_paid),
            'pending_amount': float(pending_amount),
            'unpaid_violations': float(unpaid_violations),
            'transaction_count': transaction_count,
            'wallet_balance': float(request.user.wallet_balance)
        }, status=status.HTTP_200_OK)

class WalletBalanceAPIView(APIView):
    """Get user's current wallet balance"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        return Response({
            'balance': float(request.user.wallet_balance),
            'currency': 'UGX'
        }, status=status.HTTP_200_OK)

class WalletTransactionsListAPIView(generics.ListAPIView):
    """List user's wallet transactions"""
    permission_classes = [IsAuthenticated]
    serializer_class = WalletTransactionSerializer
    
    def get_queryset(self):
        return WalletTransaction.objects.filter(user=self.request.user).order_by('-created_at')

class InitiatePesapalPaymentAPIView(APIView):
    """Initiate a PesaPal payment"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        serializer = PesapalPaymentSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        pesapal = PesapalService()
        token = pesapal.get_token()
        if not token:
            return Response({'error': 'Failed to authenticate with PesaPal'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # Register IPN
        callback_url = request.build_absolute_uri('/api/user/payments/pesapal/ipn/')
        ipn_id = pesapal.register_ipn(token, callback_url)
        if not ipn_id:
            return Response({'error': 'Failed to register IPN with PesaPal'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # Create transaction
        idempotency_key = str(uuid.uuid4())
        merchant_reference = str(uuid.uuid4())
        
        parking_session = None
        if serializer.validated_data.get('parking_session_id'):
            parking_session = ParkingSession.objects.get(id=serializer.validated_data['parking_session_id'])
            
        violation = None
        if serializer.validated_data.get('violation_id'):
            violation = Violation.objects.get(id=serializer.validated_data['violation_id'])

        trans = Transaction.objects.create(
            user=request.user,
            amount=serializer.validated_data['amount'],
            parking_session=parking_session,
            idempotency_key=idempotency_key,
            pesapal_merchant_reference=merchant_reference,
            status='pending',
            processor_response={'is_wallet_topup': serializer.validated_data.get('is_wallet_topup', False)}
        )
        
        order_data = {
            "id": merchant_reference,
            "currency": "UGX",
            "amount": float(serializer.validated_data['amount']),
            "description": serializer.validated_data['description'],
            "callback_url": serializer.validated_data['callback_url'],
            "notification_id": ipn_id,
            "billing_address": {
                "email_address": request.user.email or "user@example.com",
                "phone_number": str(request.user.phone),
                "country_code": "GH",
                "first_name": request.user.first_name,
                "last_name": request.user.last_name,
            }
        }
        
        response = pesapal.submit_order(token, order_data)
        if not response or 'order_tracking_id' not in response:
            trans.status = 'failed'
            trans.save()
            return Response({'error': 'Failed to submit order to PesaPal'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        trans.pesapal_order_tracking_id = response['order_tracking_id']
        trans.save()
        
        return Response({
            'message': 'Payment initiated',
            'redirect_url': response['redirect_url'],
            'order_tracking_id': response['order_tracking_id'],
            'merchant_reference': merchant_reference
        }, status=status.HTTP_200_OK)

class PesapalIPNAPIView(APIView):
    """Handle PesaPal IPN callbacks"""
    
    def get(self, request):
        order_tracking_id = request.query_params.get('OrderTrackingId')
        order_merchant_reference = request.query_params.get('OrderMerchantReference')
        notification_type = request.query_params.get('OrderNotificationType')
        
        if not all([order_tracking_id, order_merchant_reference]):
            return Response({'error': 'Invalid IPN parameters'}, status=status.HTTP_400_BAD_REQUEST)
        
        pesapal = PesapalService()
        token = pesapal.get_token()
        if not token:
            return Response({'error': 'Authentication failed'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        status_response = pesapal.get_transaction_status(token, order_tracking_id)
        if not status_response:
            return Response({'error': 'Failed to fetch status'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        try:
            trans = Transaction.objects.get(pesapal_merchant_reference=order_merchant_reference)
            
            p_status = status_response.get('payment_status_description', '').lower()
            if p_status == 'completed' and trans.status != 'completed':
                trans.status = 'completed'
                # Finalize parking session if exists
                if trans.parking_session:
                    trans.parking_session.end_session()
                
                # If it's a wallet top-up, credit the wallet
                is_wallet_topup = trans.processor_response.get('is_wallet_topup', False)
                if is_wallet_topup:
                    with transaction.atomic():
                        user = trans.user
                        user.wallet_balance += trans.amount
                        user.save()
                        
                        WalletTransaction.objects.create(
                            user=user,
                            amount=trans.amount,
                            transaction_type='topup',
                            description=_('Wallet top-up via PesaPal'),
                            related_transaction=trans
                        )
            elif p_status in ['failed', 'invalid']:
                trans.status = 'failed'
            
            trans.processor_response = {**trans.processor_response, **status_response}
            trans.save()
            
            return Response({
                'order_tracking_id': order_tracking_id,
                'merchant_reference': order_merchant_reference,
                'status': trans.status
            }, status=status.HTTP_200_OK)
            
        except Transaction.DoesNotExist:
            return Response({'error': 'Transaction not found'}, status=status.HTTP_404_NOT_FOUND)
