import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from django.contrib.auth.models import AnonymousUser

logger = logging.getLogger(__name__)


class RealtimeMonitorConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        user = self.scope.get('user')
        logger.info(f"WebSocket Connect Attempt: User={user}")

        if not user or isinstance(user, AnonymousUser) or not user.is_staff:
            logger.warning(f"WebSocket Connection Denied: User={user} (Anonymous or not staff)")
            await self.close()
            return

        self.group_name = 'realtime_monitor'
        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name
        )
        logger.info(f"WebSocket Connection Accepted: User={user}")
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