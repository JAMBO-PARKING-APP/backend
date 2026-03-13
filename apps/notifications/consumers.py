import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'chat_{self.conversation_id}'
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        """Handle incoming messages from WebSocket"""
        from apps.notifications.models import ChatConversation, ChatMessage
        import json
        
        data = json.loads(text_data)
        message_content = data.get('message', '').strip()
        
        if not message_content:
            return
            
        user = self.scope.get('user')
        if not user or not user.is_authenticated:
            return

        try:
            conversation = await ChatConversation.objects.aget(id=self.conversation_id)
            
            message = await ChatMessage.objects.acreate(
                conversation=conversation,
                sender=user,
                content=message_content,
                message_type='text'
            )
            
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message',
                    'message': {
                        'id': str(message.id),
                        'content': message.content,
                        'sender_id': str(user.id),
                        'sender_name': user.full_name,
                        'created_at': message.created_at.iso_with_ms() if hasattr(message.created_at, 'iso_with_ms') else message.created_at.isoformat(),
                    }
                }
            )
        except Exception as e:
            print(f"Error in ChatConsumer receive: {e}")

    async def chat_message(self, event):
        """Send message to WebSocket"""
        await self.send(text_data=json.dumps(event['message']))

class ParkingConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope["user"]
        if self.user.is_anonymous:
            await self.close()
            return

        self.user_group_name = f"user_{self.user.id}".replace("-", "_")

        await self.channel_layer.group_add(
            self.user_group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'user_group_name'):
            await self.channel_layer.group_discard(
                self.user_group_name,
                self.channel_name
            )

    async def parking_update(self, event):
        await self.send(text_data=json.dumps({
            'type': 'parking_update',
            'data': event['data']
        }))
