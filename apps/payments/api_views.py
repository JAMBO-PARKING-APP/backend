import uuid
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework import status, generics
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from apps.common.constants import TransactionStatus
from .models import PaymentMethod, Transaction, Invoice
from .serializers import PaymentMethodSerializer, TransactionSerializer
from .services import PaymentService

class PaymentMethodListView(generics.ListAPIView):
    serializer_class = PaymentMethodSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return PaymentMethod.objects.filter(user=self.request.user, is_active=True)

class InitPaymentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        session_id = request.data.get('session_id')
        payment_method_id = request.data.get('payment_method_id')
        
        try:
            # Generate idempotency key
            idempotency_key = str(uuid.uuid4())
            
            # Initialize payment through service
            result = PaymentService.initialize_payment(
                user=request.user,
                session_id=session_id,
                payment_method_id=payment_method_id,
                idempotency_key=idempotency_key
            )
            
            return Response(result, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@method_decorator(csrf_exempt, name='dispatch')
class PaymentWebhookView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            # Process webhook from payment processor
            PaymentService.process_webhook(request.body, request.META.get('HTTP_STRIPE_SIGNATURE'))
            return Response({'status': 'success'})
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

class TransactionHistoryView(generics.ListAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Transaction.objects.filter(user=self.request.user).order_by('-created_at')

class DownloadInvoiceView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, transaction_id):
        try:
            transaction = Transaction.objects.get(
                id=transaction_id,
                user=request.user,
                status=TransactionStatus.COMPLETED
            )
            
            invoice = transaction.invoice
            if invoice.pdf_file:
                response = HttpResponse(invoice.pdf_file.read(), content_type='application/pdf')
                response['Content-Disposition'] = f'attachment; filename="{invoice.invoice_number}.pdf"'
                return response
            else:
                return Response({'error': 'Invoice not available'}, status=status.HTTP_404_NOT_FOUND)
                
        except Transaction.DoesNotExist:
            return Response({'error': 'Transaction not found'}, status=status.HTTP_404_NOT_FOUND)