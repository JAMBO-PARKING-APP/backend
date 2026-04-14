import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.utils import timezone
from apps.common.utils import calculate_distance
import logging

logger = logging.getLogger(__name__)

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

    async def receive(self, text_data):
        """Handle incoming location updates from the User app"""
        try:
            data = json.loads(text_data)
            if data.get('type') == 'location_update':
                lat = float(data.get('latitude'))
                lon = float(data.get('longitude'))
                
                await self.save_user_location(lat, lon)
                
                zone_data = await self.check_zone_proximity(lat, lon)
                if zone_data:
                    await self.send(text_data=json.dumps({
                        'type': 'zone_entry',
                        'zone': zone_data,
                        'message': f"You are in {zone_data['name']}. Start parking?"
                    }))
                    
                    await self.trigger_entry_push(zone_data)

        except Exception as e:
            logger.error(f"Error in ParkingConsumer receive: {e}")

    @database_sync_to_async
    def save_user_location(self, lat, lon):
        from apps.accounts.models import UserLocation
        UserLocation.objects.create(
            user=self.user,
            latitude=lat,
            longitude=lon,
            is_driver_app=True
        )

    @database_sync_to_async
    def check_zone_proximity(self, lat, lon):
        from apps.parking.models import Zone
        from apps.parking.serializers_v2 import ZoneSerializer
        from apps.common.models import get_current_country
        
        # Get active zones in user's current country
        country = get_current_country() or self.user.country
        zones = Zone.objects.filter(is_active=True, country=country)
        
        for zone in zones:
            dist = calculate_distance(lat, lon, zone.latitude, zone.longitude)
            radius = getattr(zone, 'radius_meters', 50)
            if dist <= radius:
                return ZoneSerializer(zone).data
        return None

    @database_sync_to_async
    def trigger_entry_push(self, zone_data):
        from apps.notifications.firebase_service import send_notification_to_user
        send_notification_to_user(
            self.user,
            title="Parking Zone Detected",
            body=f"You have entered {zone_data['name']}. Start your parking session now to avoid violations.",
            data={"type": "zone_entry", "zone_id": str(zone_data['id'])}
        )

    async def parking_update(self, event):
        await self.send(text_data=json.dumps({
            'type': 'parking_update',
            'data': event['data']
        }))
