from django.db import models
from django.conf import settings

class AIChatContext(models.Model):
    """
    Stores conversational state for the AI Agent.
    Enables multi-turn flows like confirmations.
    """
    ACTION_CHOICES = [
        ('START_PARKING', 'Start Parking'),
        ('STOP_PARKING', 'Stop Parking'),
        ('TOPUP_WALLET', 'Top Up Wallet'),
    ]
    
    STEP_CHOICES = [
        ('IDLE', 'Idle'),
        ('WAITING_CONFIRMATION', 'Waiting Confirmation'),
        ('WAITING_INPUT', 'Waiting Input'),
    ]

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='ai_context')
    action_type = models.CharField(max_length=50, choices=ACTION_CHOICES, null=True, blank=True)
    action_data = models.JSONField(default=dict, blank=True)
    step = models.CharField(max_length=50, choices=STEP_CHOICES, default='IDLE')
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user} - {self.action_type} ({self.step})"
