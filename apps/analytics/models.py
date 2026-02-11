from django.db import models
from apps.common.models import BaseModel

class RevenueRecord(BaseModel):
    zone = models.ForeignKey('parking.Zone', on_delete=models.CASCADE, related_name='revenue_records')
    date = models.DateField(db_index=True)
    total_revenue = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_sessions = models.IntegerField(default=0)
    total_violations = models.IntegerField(default=0)
    average_duration_minutes = models.IntegerField(default=0)

    class Meta:
        unique_together = ['zone', 'date']

    def __str__(self):
        return f"{self.zone.name} - {self.date} (${self.total_revenue})"