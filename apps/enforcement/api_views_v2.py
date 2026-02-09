"""
Enforcement API Endpoints for User App
- View violations
- View violation details and evidence
"""

from rest_framework import generics, status
from rest_framework.decorators import permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Violation
from .serializers_v2 import ViolationListSerializer, ViolationDetailSerializer

class UserViolationsListAPIView(generics.ListAPIView):
    """List all violations for user's vehicles"""
    permission_classes = [IsAuthenticated]
    serializer_class = ViolationListSerializer
    
    def get_queryset(self):
        user_vehicles = self.request.user.vehicles.filter(is_active=True)
        
        # Filter by paid status
        paid_only = self.request.query_params.get('paid_only', 'false').lower() == 'true'
        unpaid_only = self.request.query_params.get('unpaid_only', 'false').lower() == 'true'
        
        queryset = Violation.objects.filter(vehicle__in=user_vehicles)
        
        if paid_only:
            queryset = queryset.filter(is_paid=True)
        elif unpaid_only:
            queryset = queryset.filter(is_paid=False)
        
        return queryset.order_by('-created_at')

class ViolationDetailAPIView(generics.RetrieveAPIView):
    """Get detailed information about a specific violation"""
    permission_classes = [IsAuthenticated]
    serializer_class = ViolationDetailSerializer
    lookup_field = 'pk'
    
    def get_queryset(self):
        user_vehicles = self.request.user.vehicles.filter(is_active=True)
        return Violation.objects.filter(vehicle__in=user_vehicles)

class UnpaidViolationsCountAPIView(APIView):
    """Get count of unpaid violations"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user_vehicles = request.user.vehicles.filter(is_active=True)
        count = Violation.objects.filter(
            vehicle__in=user_vehicles,
            is_paid=False
        ).count()
        
        total_amount = sum(
            v.fine_amount for v in Violation.objects.filter(
                vehicle__in=user_vehicles,
                is_paid=False
            )
        )
        
        return Response({
            'unpaid_count': count,
            'total_amount': float(total_amount)
        }, status=status.HTTP_200_OK)
