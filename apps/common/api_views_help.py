"""
API views for Help Center (static content)
"""
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework import status
from apps.common.help_content import HELP_CENTER_ITEMS


class HelpCenterListAPIView(APIView):
    """Get all help center items"""
    permission_classes = [AllowAny]

    def get(self, request):
        category = request.query_params.get('category')
        search = request.query_params.get('search', '').lower()

        items = HELP_CENTER_ITEMS

        if category:
            items = [item for item in items if item['category'].lower() == category.lower()]

        if search:
            items = [
                item for item in items
                if search in item['title'].lower() or search in item['content'].lower()
            ]

        return Response({
            'count': len(items),
            'items': items,
            'categories': sorted(set(item['category'] for item in HELP_CENTER_ITEMS))
        }, status=status.HTTP_200_OK)


class HelpCenterDetailAPIView(APIView):
    """Get single help center item"""
    permission_classes = [AllowAny]

    def get(self, request, item_id):
        item = next((item for item in HELP_CENTER_ITEMS if item['id'] == item_id), None)
        if not item:
            return Response({'error': 'Help item not found'}, status=status.HTTP_404_NOT_FOUND)
        return Response(item, status=status.HTTP_200_OK)
