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
    pagination_class = PageNumberPagination
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            from .serializers import CreateChatConversationSerializer
            return CreateChatConversationSerializer
        return ChatConversationSerializer
    
    def get_queryset(self):
        user = self.request.user
        if user.role in ['support_agent', 'admin']:
            return ChatConversation.objects.all().order_by('-created_at')
        
        if user.role == 'officer':
            from apps.parking.models import ParkingSession
            from apps.common.constants import ParkingStatus
            
            # Get users with active sessions in officer's assigned zones
            assigned_zones = user.assigned_zones.all()
            active_users_in_zones = ParkingSession.objects.filter(
                zone__in=assigned_zones,
                status=ParkingStatus.ACTIVE
            ).values_list('vehicle__user_id', flat=True)
            
            return ChatConversation.objects.filter(
                Q(assigned_agent=user) | 
                Q(assigned_agent__isnull=True, user_id__in=active_users_in_zones)
            ).distinct().order_by('-created_at')

        return ChatConversation.objects.filter(user=user).order_by('-created_at')
    
    def create(self, request, *args, **kwargs):
        """Create new support conversation"""
        if request.user.role == 'driver':
            from apps.parking.models import ParkingSession
            from apps.common.constants import ParkingStatus
            has_active_session = ParkingSession.objects.filter(
                vehicle__user=request.user,
                status=ParkingStatus.ACTIVE
            ).exists()
            
            if not has_active_session:
                return Response(
                    {'error': 'You must have an active parking session to initiate a chat.'},
                    status=status.HTTP_403_FORBIDDEN
                )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(user=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def close(self, request, pk=None):
        """Close/resolve a conversation"""
        conversation = self.get_object()
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
        user = request.user
        if user.role not in ['support_agent', 'officer', 'admin']:
            if conversation.user != user:
                return Response(
                    {'error': 'You do not have permission to view this conversation'},
                    status=status.HTTP_403_FORBIDDEN
                )
        elif user.role == 'officer':
             # For officers, check if they are either assigned or the user is in their zone with active session
             if conversation.assigned_agent and conversation.assigned_agent != user:
                 return Response(
                     {'error': 'This conversation is assigned to another agent'},
                     status=status.HTTP_403_FORBIDDEN
                 )
             
             from apps.parking.models import ParkingSession
             from apps.common.constants import ParkingStatus
             has_active_session_in_zone = ParkingSession.objects.filter(
                 vehicle__user=conversation.user,
                 zone__in=user.assigned_zones.all(),
                 status=ParkingStatus.ACTIVE
             ).exists()
             
             if not has_active_session_in_zone and conversation.assigned_agent != user:
                 return Response(
                     {'error': 'User must have an active session in your assigned zones to view chat.'},
                     status=status.HTTP_403_FORBIDDEN
                 )
        elif conversation.assigned_agent and conversation.assigned_agent != user:
             if user.role != 'admin':
                return Response(
                    {'error': 'This conversation is assigned to another agent'},
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
        user = request.user
        if user.role not in ['support_agent', 'officer', 'admin']:
            if conversation.user != user:
                return Response(
                    {'error': 'You do not have permission to message in this conversation'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Also ensure driver still has active session to continue chatting? 
            # The requirement said "users can only initiate a chat when they have an active session".
            # Usually, once started, they can finish it, but let's stick to strict if needed.
            # "initiate" implies create. So continue is fine? Let's keep it lenient for continue.
            
        elif user.role == 'officer':
             from apps.parking.models import ParkingSession
             from apps.common.constants import ParkingStatus
             
             # Restricted to users with active sessions in officer's zone
             is_valid_chat = ParkingSession.objects.filter(
                 vehicle__user=conversation.user,
                 zone__in=user.assigned_zones.all(),
                 status=ParkingStatus.ACTIVE
             ).exists()
             
             if not is_valid_chat and conversation.assigned_agent != user:
                 return Response(
                     {'error': 'You can only message users with active sessions in your assigned zones.'},
                     status=status.HTTP_403_FORBIDDEN
                 )
             
             if conversation.assigned_agent and conversation.assigned_agent != user:
                 return Response(
                     {'error': 'This conversation is assigned to another agent'},
                     status=status.HTTP_403_FORBIDDEN
                 )
        elif conversation.assigned_agent and conversation.assigned_agent != user:
             if user.role != 'admin':
                return Response(
                    {'error': 'This conversation is assigned to another agent'},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        message = ChatMessage.objects.create(
            conversation=conversation,
            sender=request.user,
            content=request.data.get('content', ''),
            message_type=request.data.get('message_type', 'text')
        )
        
        if request.user == conversation.user and conversation.status == 'open':
            conversation.status = 'in_progress'
            conversation.save()
        
        if conversation.assigned_agent and request.user == conversation.user:
            from apps.notifications.firebase_service import send_notification_to_user
            send_notification_to_user(
                user=conversation.assigned_agent,
                title=f"New message from {request.user.full_name}",
                body=message.content[:100], 
                data={
                    'type': 'chat_message',
                    'conversation_id': str(conversation.id),
                    'sender_id': str(request.user.id),
                }
            )
        
        if 'attachment' in request.FILES:
            message.attachment = request.FILES['attachment']
            message.message_type = 'file'
            message.save()
        
        from asgiref.sync import async_to_sync
        from channels.layers import get_channel_layer
        
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(
            f'chat_{conversation.id}',
            {
                'type': 'chat_message',
                'message': ChatMessageSerializer(message).data
            }
        )
        
        return Response(
            ChatMessageSerializer(message).data,
            status=status.HTTP_201_CREATED
        )
    
    @action(detail=True, methods=['post'])
    def mark_messages_read(self, request, pk=None):
        """Mark all messages in conversation as read"""
        conversation = self.get_object()
        
        if conversation.user != request.user and conversation.assigned_agent != request.user:
            return Response(
                {'error': 'You do not have permission to access this conversation'},
                status=status.HTTP_403_FORBIDDEN
            )
        
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
