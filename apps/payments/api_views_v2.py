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
from django.conf import settings
from rest_framework import generics, status
from rest_framework.decorators import permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .serializers_v2 import (
    TransactionSerializer, PaymentMethodSerializer, InvoiceSerializer,
    TransactionListSerializer, PesapalPaymentSerializer, WalletTransactionSerializer,
    PaymentGatewayConfigSerializer
)
from .models import Transaction, PaymentMethod, Invoice, WalletTransaction, PaymentGatewayConfig, PaymentGateway
from .pesapal_service import PesapalService
from apps.enforcement.models import Violation
from apps.parking.models import ParkingSession, ParkingStatus, Reservation

class PesapalPreWarmView(APIView):
    """
    Pre-warm Pesapal cache by fetching auth token and registering IPN in background.
    Called by mobile app when user enters payment flow to reduce latency.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"PesapalPreWarmView: Pre-warming for user {request.user.id}")
        country = "Uganda" 
        if hasattr(request.user, 'country') and request.user.country:
            country = request.user.country 
            
        pesapal_config = PesapalService.get_config_for_country(country)
        service = PesapalService(config_obj=pesapal_config)
        token = service.get_token()
        
        if token:
            cache_key = f"pesapal_ipn_id_{(service.consumer_key or '')[:8]}"
            from django.core.cache import cache
            if not cache.get(cache_key):
                service.register_ipn(token)
                
        return Response({'status': 'pre-warm initiated'}, status=status.HTTP_200_OK)

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
            request.user.payment_methods.exclude(id=pk).update(is_default=False)
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
        reservation_id = request.data.get('reservation_id')
        
        if not amount or not payment_method_id:
            return Response({
                'error': 'amount and payment_method_id are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            amount = Decimal(str(amount))
            payment_method = request.user.payment_methods.get(
                id=payment_method_id,
                is_active=True
            )
            
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
            
            reservation = None
            if reservation_id:
                reservation = Reservation.objects.get(
                    id=reservation_id,
                    vehicle__user=request.user
                )
                if reservation.status != 'pending_payment':
                    return Response({
                        'error': f'Reservation is in status {reservation.status}, not pending payment'
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            idempotency_key = str(uuid.uuid4())
            
            trans = Transaction.objects.create(
                user=request.user,
                amount=amount,
                payment_method=payment_method,
                parking_session=parking_session,
                reservation=reservation,
                idempotency_key=idempotency_key,
                status='completed' 
            )
            if reservation:
                from apps.parking.services.reservation_service import ReservationService
                ReservationService.confirm_reservation(reservation, payment_method='wallet' if payment_method.card_brand == 'wallet' else 'card')
            if violation:
                violation.is_paid = True
                violation.paid_at = trans.created_at
                violation.save()
            
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
        except Reservation.DoesNotExist:
            return Response({
                'error': 'Reservation not found'
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
        country = getattr(request.user, 'country', None)
        if not country:
            return Response({
                'balance': float(request.user.wallet_balance_legacy),
                'currency': 'UGX'
            }, status=status.HTTP_200_OK)
            
        from apps.accounts.models import Wallet
        wallet, _ = Wallet.objects.get_or_create(user=request.user, country=country)
        
        return Response({
            'balance': float(wallet.balance),
            'currency': country.currency
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
        country = getattr(request.user, 'country', None)
        config_obj = PesapalService.get_config_for_country(country)
        
        if config_obj:
            pesapal = PesapalService(config_obj=config_obj)
        else:

            pesapal = PesapalService()
        merchant_reference = str(uuid.uuid4())
        idempotency_key = merchant_reference
        
        amount = serializer.validated_data['amount']
        payment_type = serializer.validated_data.get('payment_type', 'MOBILE_MONEY')
        currency = country.currency if country else "UGX"
        
        charge_amount_processor = amount
        charge_currency_processor = currency
        
        if payment_type == 'CARD':
            exchange_rate = getattr(settings, 'PESAPAL_USD_EXCHANGE_RATE', 3700)
            charge_amount_processor = round(amount / Decimal(str(exchange_rate)), 2)
            charge_currency_processor = "USD"
            
        parking_session = None
        if serializer.validated_data.get('parking_session_id'):
            try:
                parking_session = ParkingSession.objects.get(id=serializer.validated_data['parking_session_id'])
            except ParkingSession.DoesNotExist:
                return Response({'error': 'Parking session not found'}, status=status.HTTP_404_NOT_FOUND)
            
        violation = None
        if serializer.validated_data.get('violation_id'):
            try:
                violation = Violation.objects.get(id=serializer.validated_data['violation_id'])
            except Violation.DoesNotExist:
                return Response({'error': 'Violation not found'}, status=status.HTTP_404_NOT_FOUND)

        reservation = None
        if serializer.validated_data.get('reservation_id'):
            try:
                reservation = Reservation.objects.get(id=serializer.validated_data['reservation_id'])
            except Reservation.DoesNotExist:
                return Response({'error': 'Reservation not found'}, status=status.HTTP_404_NOT_FOUND)

        trans = Transaction.objects.create(
            user=request.user,
            amount=amount,
            parking_session=parking_session,
            reservation=reservation,
            idempotency_key=idempotency_key,
            pesapal_merchant_reference=merchant_reference,
            charge_amount_processor=charge_amount_processor,
            charge_currency_processor=charge_currency_processor,
            status='pending',
            processor_response={'is_wallet_topup': serializer.validated_data.get('is_wallet_topup', False)}
        )
        
        response = pesapal.create_payment(
            amount=charge_amount_processor,
            merchant_reference=merchant_reference,
            description=serializer.validated_data['description'],
            user=request.user,
            currency=charge_currency_processor
        )

        if not response or 'order_tracking_id' not in response:
            trans.status = 'failed'
            trans.processor_response = response if isinstance(response, dict) else {'error': str(response)}
            trans.save()
            error_msg = response.get('error') if response and isinstance(response, dict) else 'Unknown error'
            return Response({'error': f'Failed to initiate payment: {error_msg}'}, status=status.HTTP_400_BAD_REQUEST)
        
        trans.pesapal_order_tracking_id = response['order_tracking_id']
        trans.save()
        
        redirect_url = response.get('redirect_url')
        if not redirect_url:
            logger.error(f"Pesapal response missing redirect_url: {response}")
            return Response({'error': 'Failed to get payment redirect URL from Pesapal'}, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            'message': 'Payment initiated',
            'redirect_url': redirect_url,
            'order_tracking_id': response['order_tracking_id'],
            'merchant_reference': merchant_reference
        }, status=status.HTTP_200_OK)

class PesapalUserCallbackView(APIView):
    """Handle PesaPal User Redirect Callback"""
    permission_classes = [AllowAny]
    
    def get(self, request):
        order_tracking_id = request.query_params.get('OrderTrackingId')
        order_merchant_reference = request.query_params.get('OrderMerchantReference')
        
        if not all([order_tracking_id, order_merchant_reference]):
            return Response({'error': 'Invalid parameters'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            trans = Transaction.objects.get(pesapal_merchant_reference=order_merchant_reference)
            country = getattr(trans.user, 'country', None)
            config_obj = PesapalService.get_config_for_country(country)
            
            if config_obj:
                pesapal = PesapalService(config_obj=config_obj)
            else:
                pesapal = PesapalService()
            
            status_response = pesapal.get_transaction_status(order_tracking_id)
            p_status = status_response.get('payment_status_description', '').lower()
            if p_status == 'completed' and trans.status != 'completed':
                trans.status = 'completed'
                if trans.parking_session:
                    trans.parking_session.end_session()
                
                if trans.reservation:
                    from apps.parking.services.reservation_service import ReservationService
                    ReservationService.confirm_reservation(trans.reservation, payment_method='pesapal')
                
                parking_intent = trans.processor_response.get('parking_intent')
                if parking_intent and not trans.parking_session:
                    try:
                        from apps.parking.models import ParkingSession, Zone, ParkingSlot, Vehicle
                        from apps.common.constants import ParkingStatus, SlotStatus
                        from apps.notifications.notification_triggers import notify_parking_started
                        from datetime import timedelta
                        
                        vehicle_id = parking_intent.get('vehicle_id')
                        zone_id = parking_intent.get('zone_id')
                        slot_id = parking_intent.get('slot_id')
                        duration_hours = parking_intent.get('duration_hours', 1)
                        
                        vehicle = Vehicle.objects.get(id=vehicle_id)
                        zone = Zone.objects.get(id=zone_id)
                        parking_slot = ParkingSlot.objects.filter(id=slot_id).first() if slot_id else None
                        
                        planned_end = trans.created_at + timedelta(hours=float(duration_hours))
                        
                        session = ParkingSession.objects.create(
                            vehicle=vehicle,
                            zone=zone,
                            parking_slot=parking_slot,
                            planned_end_time=planned_end,
                            estimated_cost=trans.amount,
                            status=ParkingStatus.ACTIVE
                        )
                        trans.parking_session = session
                        
                        if parking_slot:
                            parking_slot.status = SlotStatus.OCCUPIED
                            parking_slot.save()
                            
                        notify_parking_started(session)
                    except Exception as e:
                        import logging
                        logging.getLogger(__name__).error(f"Failed to create parking session from intent: {str(e)}")
                is_wallet_topup = trans.processor_response.get('is_wallet_topup', False) if trans.processor_response else False
                if is_wallet_topup:
                    with transaction.atomic():
                        user = trans.user
                        country = getattr(user, 'country', None)
                        if country:
                            from apps.accounts.models import Wallet
                            from django.db.models import F
                            wallet, _ = Wallet.objects.get_or_create(user=user, country=country)
                            wallet.balance = F('balance') + trans.amount
                            wallet.save(update_fields=['balance'])
                        else:
                            from django.db.models import F
                            user.wallet_balance_legacy = F('wallet_balance_legacy') + trans.amount
                            user.save(update_fields=['wallet_balance_legacy'])
                        
                        from django.utils.translation import gettext as _
                        WalletTransaction.objects.create(
                            user=user,
                            amount=trans.amount,
                            transaction_type='topup',
                            description=_('Wallet top-up via PesaPal'),
                            status='completed',
                            related_transaction=trans
                        )
                        from apps.notifications.notification_triggers import notify_payment_success
                        wallet_tx = WalletTransaction.objects.filter(related_transaction=trans).first()
                        if wallet_tx:
                            notify_payment_success(wallet_tx)
                else:
                    from apps.notifications.notification_triggers import notify_payment_success
                    notify_payment_success(trans)
                
                payment_token = status_response.get('payment_token')
                card_details = status_response.get('card_details', {})
                if payment_token:
                    PaymentMethod.objects.update_or_create(
                        user=trans.user,
                        pesapal_token=payment_token,
                        defaults={
                            'card_brand': card_details.get('card_type', 'visa'),
                            'card_last_four': card_details.get('card_number', '****')[-4:],
                            'gateway': PaymentGateway.PESAPAL,
                            'is_active': True
                        }
                    )
            elif p_status in ['failed', 'invalid', 'rejected']:
                trans.status = 'failed'
                
            trans.processor_response = {**trans.processor_response, **status_response}
            trans.save()
            from django.http import HttpResponse
            html_content = f"""
            <html>
                <head><title>Payment {p_status.title()}</title></head>
                <body style="text-align: center; padding: 20px; font-family: sans-serif;">
                    <h1>Payment {p_status.title()}</h1>
                    <p>Reference: {order_merchant_reference}</p>
                    <p>You can verify this in the app.</p>
                </body>
            </html>
            """
            return HttpResponse(html_content)

        except Transaction.DoesNotExist:
            return Response({'error': 'Transaction not found'}, status=status.HTTP_404_NOT_FOUND)

class PesapalIPNAPIView(APIView):
    """Handle PesaPal IPN callbacks"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Handle POST IPN"""
        return self.process_ipn(request.data)

    def get(self, request):
        """Handle GET IPN"""
        return self.process_ipn(request.query_params)
    
    def process_ipn(self, data):
        order_tracking_id = data.get('OrderTrackingId')
        order_merchant_reference = data.get('OrderMerchantReference')
        notification_type = data.get('OrderNotificationType')
        
        if not all([order_tracking_id, order_merchant_reference]):
            return Response({'error': 'Invalid IPN parameters'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            trans = Transaction.objects.get(pesapal_merchant_reference=order_merchant_reference)
            country = getattr(trans.user, 'country', None)
            config_obj = PesapalService.get_config_for_country(country)
            
            if config_obj:
                pesapal = PesapalService(config_obj=config_obj)
            else:
                pesapal = PesapalService()
            
            status_response = pesapal.get_transaction_status(order_tracking_id)
            
            p_status = status_response.get('payment_status_description', '').lower()
            if p_status == 'completed' and trans.status != 'completed':
                trans.status = 'completed'
                if trans.parking_session:
                    trans.parking_session.end_session()
                
                if trans.reservation:
                    from apps.parking.services.reservation_service import ReservationService
                    ReservationService.confirm_reservation(trans.reservation, payment_method='pesapal')
                is_wallet_topup = trans.processor_response.get('is_wallet_topup', False) if trans.processor_response else False
                if is_wallet_topup:
                    with transaction.atomic():
                        user = trans.user
                        country = getattr(user, 'country', None)
                        if country:
                            from apps.accounts.models import Wallet
                            from django.db.models import F
                            wallet, _ = Wallet.objects.get_or_create(user=user, country=country)
                            wallet.balance = F('balance') + trans.amount
                            wallet.save(update_fields=['balance'])
                        else:
                            from django.db.models import F
                            user.wallet_balance_legacy = F('wallet_balance_legacy') + trans.amount
                            user.save(update_fields=['wallet_balance_legacy'])
                        
                        from django.utils.translation import gettext as _
                        WalletTransaction.objects.create(
                            user=user,
                            amount=trans.amount,
                            transaction_type='topup',
                            description=_('Wallet top-up via PesaPal'),
                            status='completed',
                            related_transaction=trans
                        )
                
                        from apps.notifications.notification_triggers import notify_payment_success
                        wallet_tx = WalletTransaction.objects.filter(related_transaction=trans).first()
                        if wallet_tx:
                            notify_payment_success(wallet_tx)
                else:
                    from apps.notifications.notification_triggers import notify_payment_success
                    notify_payment_success(trans)
                payment_token = status_response.get('payment_token')
                card_details = status_response.get('card_details', {})
                if payment_token:
                    PaymentMethod.objects.update_or_create(
                        user=trans.user,
                        pesapal_token=payment_token,
                        defaults={
                            'card_brand': card_details.get('card_type', 'visa'),
                            'card_last_four': card_details.get('card_number', '****')[-4:],
                            'gateway': PaymentGateway.PESAPAL,
                            'is_active': True
                        }
                    )
            elif p_status in ['failed', 'invalid', 'rejected']:
                trans.status = 'failed'
            
            trans.processor_response = {**trans.processor_response, **status_response}
            trans.save()
            
            return Response({
                'orderNotificationType': notification_type,
                'orderTrackingId': order_tracking_id,
                'orderMerchantReference': order_merchant_reference,
                'status': 200
            }, status=status.HTTP_200_OK)
            
        except Transaction.DoesNotExist:
            return Response({'error': 'Transaction not found'}, status=status.HTTP_404_NOT_FOUND)

class ExecutePesapalTokenPaymentAPIView(APIView):
    """Execute a payment using a saved Pesapal token (one-click)"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        payment_method_id = request.data.get('payment_method_id')
        amount = request.data.get('amount')
        description = request.data.get('description', 'One-click payment')
        
        if not all([payment_method_id, amount]):
            return Response({'error': 'payment_method_id and amount are required'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            payment_method = PaymentMethod.objects.get(id=payment_method_id, user=request.user, is_active=True)
            if not payment_method.pesapal_token:
                return Response({'error': 'This payment method does not have a valid Pesapal token'}, status=status.HTTP_400_BAD_REQUEST)
                
            country = getattr(request.user, 'country', None)
            config_obj = PesapalService.get_config_for_country(country)
            pesapal = PesapalService(config_obj=config_obj) if config_obj else PesapalService()
            
            merchant_reference = str(uuid.uuid4())
            charge_amount = Decimal(str(amount))
            exchange_rate = getattr(settings, 'PESAPAL_USD_EXCHANGE_RATE', 3700)
            charge_amount_usd = round(charge_amount / Decimal(str(exchange_rate)), 2)
            
            trans = Transaction.objects.create(
                user=request.user,
                amount=charge_amount,
                payment_method=payment_method,
                idempotency_key=merchant_reference,
                pesapal_merchant_reference=merchant_reference,
                charge_amount_processor=charge_amount_usd,
                charge_currency_processor="USD",
                status='pending'
            )
            
            response = pesapal.create_payment(
                amount=charge_amount_usd,
                merchant_reference=merchant_reference,
                description=description,
                user=request.user,
                currency="USD",
                card_token=payment_method.pesapal_token
            )
            
            if not response or 'order_tracking_id' not in response:
                trans.status = 'failed'
                trans.save()
                return Response({'error': 'Failed to initiate token payment'}, status=status.HTTP_400_BAD_REQUEST)
                
            trans.pesapal_order_tracking_id = response.get('order_tracking_id')
            p_status = response.get('status')
            if p_status == '200' and not response.get('redirect_url'):
                 trans.status = 'completed'
            
            trans.save()
            
            return Response({
                'message': 'Token payment processed',
                'redirect_url': response.get('redirect_url'),
                'order_tracking_id': response.get('order_tracking_id'),
                'status': trans.status
            }, status=status.HTTP_200_OK)
            
        except PaymentMethod.DoesNotExist:
            return Response({'error': 'Payment method not found'}, status=status.HTTP_404_NOT_FOUND)

class AvailablePaymentGatewaysAPIView(generics.ListAPIView):
    """List available payment gateways for user's country"""
    permission_classes = [IsAuthenticated]
    serializer_class = PaymentGatewayConfigSerializer
    
    def get_queryset(self):
        country = getattr(self.request.user, 'country', None)
        return PaymentGatewayConfig.objects.filter(
            country=country,
            is_active=True
        ).order_by('-priority', 'name')


class OfficerInitiatePesapalPaymentAPIView(APIView):
    """Initiate PesaPal payment for guest parking sessions by officers"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from apps.accounts.models import User
        from apps.common.constants import UserRole
        
        # Check if user is officer
        user_role = getattr(request.user, 'role', None)
        if user_role != UserRole.OFFICER:
            return Response(
                {'error': 'Only officers can create guest session payments'},
                status=status.HTTP_403_FORBIDDEN
            )

        session_id = request.data.get('session_id')
        phone_number = request.data.get('phone_number')
        
        if not session_id:
            return Response(
                {'error': 'session_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            from apps.enforcement.models import GuestParkingSession
            guest_session = GuestParkingSession.objects.get(id=session_id, officer=request.user)
        except GuestParkingSession.DoesNotExist:
            return Response(
                {'error': 'Guest parking session not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Create transaction for guest session
        merchant_reference = str(uuid.uuid4())
        idempotency_key = merchant_reference

        with transaction.atomic():
            trans = Transaction.objects.create(
                user=request.user,
                amount=guest_session.estimated_cost,
                pesapal_merchant_reference=merchant_reference,
                idempotency_key=idempotency_key,
                status='pending',
                processor_response={
                    'guest_session_id': str(guest_session.id),
                    'is_guest_session': True
                }
            )

            # Update guest session payment status
            guest_session.payment_status = 'pending'
            guest_session.payment_transaction = trans
            guest_session.save()

        # Initiate PesaPal payment
        country = getattr(request.user, 'country', None)
        pesapal_config = PesapalService.get_config_for_country(country)
        pesapal = PesapalService(config_obj=pesapal_config) if pesapal_config else PesapalService()

        currency = country.currency if country else "UGX"
        response = pesapal.create_payment(
            amount=guest_session.estimated_cost,
            merchant_reference=merchant_reference,
            description=f"Parking Session: {guest_session.license_plate} - {guest_session.zone.name}",
            user=request.user,
            currency=currency
        )

        if not response or 'order_tracking_id' not in response:
            trans.status = 'failed'
            trans.save()
            guest_session.payment_status = 'failed'
            guest_session.save()
            return Response(
                {'error': 'Failed to initiate payment with PesaPal'},
                status=status.HTTP_400_BAD_REQUEST
            )

        trans.pesapal_order_tracking_id = response.get('order_tracking_id')
        trans.processor_response = response
        trans.save()

        return Response({
            'success': True,
            'payment_url': response.get('redirect_url'),
            'order_id': response.get('order_tracking_id'),
            'merchant_reference': merchant_reference,
            'amount': str(guest_session.estimated_cost),
            'currency': currency
        }, status=status.HTTP_200_OK)


class OfficerPesapalCallbackAPIView(APIView):
    """Handle PesaPal payment callback for guest parking sessions"""
    permission_classes = [AllowAny]

    def get(self, request):
        import logging
        logger = logging.getLogger(__name__)
        
        order_tracking_id = request.query_params.get('OrderTrackingId')
        merchant_reference = request.query_params.get('OrderMerchantReference')

        if not order_tracking_id:
            return Response(
                {'error': 'OrderTrackingId is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get transaction
        try:
            trans = Transaction.objects.get(pesapal_merchant_reference=merchant_reference)
        except Transaction.DoesNotExist:
            logger.error(f"Officer payment transaction not found: {merchant_reference}")
            return Response(
                {'error': 'Payment transaction not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Check payment status with PesaPal
        pesapal = PesapalService()
        status_response = pesapal.get_transaction_status(order_tracking_id)

        if not status_response:
            return Response(
                {'error': 'Could not verify payment status'},
                status=status.HTTP_400_BAD_REQUEST
            )

        payment_status = status_response.get('payment_status_description')

        with transaction.atomic():
            if payment_status == "Completed":
                trans.status = 'completed'
                
                # Update guest session payment
                if trans.processor_response and trans.processor_response.get('is_guest_session'):
                    from apps.enforcement.models import GuestParkingSession
                    try:
                        guest_session = GuestParkingSession.objects.get(
                            id=trans.processor_response['guest_session_id']
                        )
                        guest_session.payment_status = 'completed'
                        guest_session.status = 'active'  # Activate session after payment
                        guest_session.save()
                        logger.info(f"Guest session {guest_session.id} activated after payment")
                    except GuestParkingSession.DoesNotExist:
                        logger.error(f"Guest session not found for transaction {trans.id}")
                        
            elif payment_status == "Failed":
                trans.status = 'failed'
                if trans.processor_response and trans.processor_response.get('is_guest_session'):
                    from apps.enforcement.models import GuestParkingSession
                    try:
                        guest_session = GuestParkingSession.objects.get(
                            id=trans.processor_response['guest_session_id']
                        )
                        guest_session.payment_status = 'failed'
                        guest_session.status = 'cancelled'
                        guest_session.save()
                    except GuestParkingSession.DoesNotExist:
                        pass

            trans.processor_response = status_response
            trans.save()

        return Response({
            'status': 'success',
            'payment_status': payment_status,
            'merchant_reference': merchant_reference
        })
