import json
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth.models import AnonymousUser


class RealtimeMonitorConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        if isinstance(self.scope['user'], AnonymousUser) or not self.scope['user'].is_staff:
            await self.close()
            return

        self.group_name = 'realtime_monitor'
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(
            self.group_name,
            self.channel_name
        )

    async def receive(self, text_data):
        pass

    async def send_monitor_update(self, event):
        await self.send(text_data=json.dumps(event['data']))