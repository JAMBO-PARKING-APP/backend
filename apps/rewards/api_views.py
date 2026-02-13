from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import LoyaltyAccount, PointTransaction
from .serializers import LoyaltyAccountSerializer, PointTransactionSerializer
from .services import LoyaltyService

class LoyaltyBalanceAPIView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        account = LoyaltyService.get_or_create_account(request.user)
        serializer = LoyaltyAccountSerializer(account)
        return Response(serializer.data)

class LoyaltyHistoryAPIView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = PointTransactionSerializer

    def get_queryset(self):
        return PointTransaction.objects.filter(account__user=self.request.user).order_by('-created_at')
