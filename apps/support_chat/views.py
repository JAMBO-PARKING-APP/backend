from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from .services import ReasoningAIService as AIService

class AskAIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        query = request.data.get('query')
        if not query:
            return Response({'error': 'Query is required'}, status=status.HTTP_400_BAD_REQUEST)

        # Optional location data
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')

        service = AIService()
        response_text = service.get_response(
            user=request.user,
            query=query,
            latitude=latitude,
            longitude=longitude
        )

        return Response({
            'response': response_text,
            'suggested_actions': service._generate_suggested_actions(request.user, response_text)
        })
