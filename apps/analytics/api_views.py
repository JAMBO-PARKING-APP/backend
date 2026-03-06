from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from django.db.models import Sum, Count
from django.utils import timezone
from datetime import timedelta
from apps.parking.models import ParkingSession, Zone
from apps.accounts.models import User
from apps.enforcement.models import Violation
from apps.payments.models import Transaction, WalletTransaction
from apps.payments.serializers_v2 import TransactionListSerializer, WalletTransactionSerializer
from apps.common.constants import ParkingStatus

from rest_framework import generics

class AdminDashboardStatsAPIView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        today = timezone.now().date()
        yesterday = today - timedelta(days=1)
        total_revenue = ParkingSession.objects.filter(status=ParkingStatus.COMPLETED).aggregate(total=Sum('final_cost'))['total'] or 0
        today_revenue = ParkingSession.objects.filter(
            status=ParkingStatus.COMPLETED, 
            updated_at__date=today
        ).aggregate(total=Sum('final_cost'))['total'] or 0
        month_start = today.replace(day=1)
        monthly_revenue = ParkingSession.objects.filter(
            status=ParkingStatus.COMPLETED,
            updated_at__date__gte=month_start
        ).aggregate(total=Sum('final_cost'))['total'] or 0
        active_sessions_count = ParkingSession.objects.filter(status=ParkingStatus.ACTIVE).count()
        total_users = User.objects.count()
        total_zones = Zone.objects.filter(is_active=True).count()
        zones = Zone.objects.filter(is_active=True)
        total_capacity = sum([z.capacity for z in zones])
        global_occupancy = (active_sessions_count / total_capacity * 100) if total_capacity > 0 else 0

        return Response({
            'total_revenue': float(total_revenue),
            'today_revenue': float(today_revenue),
            'monthly_revenue': float(monthly_revenue),
            'active_sessions': active_sessions_count,
            'total_users': total_users,
            'total_zones': total_zones,
            'global_occupancy': round(global_occupancy, 2),
            'currency': 'UGX'
        })

class AdminTransactionListAPIView(generics.ListAPIView):
    """List all user transactions for admin view"""
    queryset = Transaction.objects.all().order_by('-created_at')
    serializer_class = TransactionListSerializer
    permission_classes = [IsAdminUser]

class AdminRefundListAPIView(generics.ListAPIView):
    """List all refunds for admin view"""
    queryset = WalletTransaction.objects.filter(transaction_type='refund').order_by('-created_at')
    serializer_class = WalletTransactionSerializer
    permission_classes = [IsAdminUser]
