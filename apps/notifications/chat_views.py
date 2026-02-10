from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.utils import timezone
from django.db.models import Q
from .models import ChatConversation, ChatMessage
from .serializers import ChatConversationSerializer, ChatMessageSerializer


class ChatConversationViewSet(viewsets.ModelViewSet):
    """
    API ViewSet for chat conversations
    - List all conversations for authenticated user
    - Create new conversation
    - Retrieve conversation details
    - Update conversation status
    - Close/resolve conversation
    """
    serializer_class = ChatConversationSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = PageNumberPagination
    
    def get_queryset(self):
        user = self.request.user
        # Users see their conversations, support agents see assigned conversations
        if user.role == 'support_agent':
            return ChatConversation.objects.filter(assigned_agent=user).order_by('-created_at')
        return ChatConversation.objects.filter(user=user).order_by('-created_at')
    
    def create(self, request, *args, **kwargs):
        """Create new support conversation"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(user=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def close(self, request, pk=None):
        """Close/resolve a conversation"""
        conversation = self.get_object()
        
        # Only the assigned agent or the user can close
        if conversation.user != request.user and conversation.assigned_agent != request.user:
            return Response(
                {'error': 'You do not have permission to close this conversation'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        conversation.status = 'resolved'
        conversation.resolved_at = timezone.now()
        conversation.save()
        
        return Response(
            ChatConversationSerializer(conversation).data,
            status=status.HTTP_200_OK
        )
    
    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """Get all messages in a conversation"""
        conversation = self.get_object()
        
        # Check permission
        if conversation.user != request.user and conversation.assigned_agent != request.user:
            return Response(
                {'error': 'You do not have permission to view this conversation'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        messages = conversation.messages.all()
        page = self.paginate_queryset(messages)
        if page is not None:
            serializer = ChatMessageSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = ChatMessageSerializer(messages, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        """Send a message in a conversation"""
        conversation = self.get_object()
        
        # Check permission
        if conversation.user != request.user and conversation.assigned_agent != request.user:
            return Response(
                {'error': 'You do not have permission to message in this conversation'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Create message
        message = ChatMessage.objects.create(
            conversation=conversation,
            sender=request.user,
            content=request.data.get('content', ''),
            message_type=request.data.get('message_type', 'text')
        )
        
        # If user sends message and conversation is open, change status to in_progress
        if request.user == conversation.user and conversation.status == 'open':
            conversation.status = 'in_progress'
            conversation.save()
        
        # Handle file attachment if provided
        if 'attachment' in request.FILES:
            message.attachment = request.FILES['attachment']
            message.message_type = 'file'
            message.save()
        
        return Response(
            ChatMessageSerializer(message).data,
            status=status.HTTP_201_CREATED
        )
    
    @action(detail=True, methods=['post'])
    def mark_messages_read(self, request, pk=None):
        """Mark all messages in conversation as read"""
        conversation = self.get_object()
        
        # Check permission
        if conversation.user != request.user and conversation.assigned_agent != request.user:
            return Response(
                {'error': 'You do not have permission to access this conversation'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Mark unread messages as read (excluding messages sent by the user)
        unread_messages = conversation.messages.filter(is_read=False).exclude(sender=request.user)
        unread_messages.update(is_read=True, read_at=timezone.now())
        
        return Response(
            {'status': 'Messages marked as read'},
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Get count of unread conversations and messages"""
        user = request.user
        
        if user.role == 'support_agent':
            unread_conversations = ChatConversation.objects.filter(
                assigned_agent=user,
                status='open'
            ).count()
            unread_messages = ChatMessage.objects.filter(
                conversation__assigned_agent=user,
                is_read=False
            ).exclude(sender=user).count()
        else:
            unread_conversations = ChatConversation.objects.filter(
                user=user,
                status__in=['open', 'in_progress']
            ).count()
            unread_messages = ChatMessage.objects.filter(
                conversation__user=user,
                is_read=False
            ).exclude(sender=user).count()
        
        return Response({
            'unread_conversations': unread_conversations,
            'unread_messages': unread_messages,
        })
