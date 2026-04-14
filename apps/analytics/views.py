from django.views.generic import TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.utils import timezone
from django.db.models import Sum, Count, Min, Max
from django.conf import settings
from datetime import timedelta
import json
import logging
from apps.analytics.models import RevenueRecord
from apps.common.tasks import check_system_health

logger = logging.getLogger(__name__)

class AdminRequiredMixin(UserPassesTestMixin):
    def test_func(self):
        return self.request.user.is_superuser or self.request.user.is_staff

class RevenueReportView(LoginRequiredMixin, AdminRequiredMixin, TemplateView):
    template_name = 'analytics/revenue_report.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        today = timezone.now().date()
        start_date_str = self.request.GET.get('start_date')
        end_date_str = self.request.GET.get('end_date')
        
        if start_date_str:
            start_date = timezone.datetime.strptime(start_date_str, '%Y-%m-%d').date()
        else:
            start_date = today - timedelta(days=30) 
            
        if end_date_str:
            end_date = timezone.datetime.strptime(end_date_str, '%Y-%m-%d').date()
        else:
            end_date = today
            
        context['start_date'] = start_date
        context['end_date'] = end_date
        
        records = RevenueRecord.objects.filter(
            date__range=[start_date, end_date]
        ).order_by('date')
        
        aggregates = records.aggregate(
            total_rev=Sum('total_revenue'),
            total_sess=Sum('total_sessions'),
            total_viol=Sum('total_violations')
        )
        
        context['total_revenue'] = aggregates['total_rev'] or 0
        context['total_sessions'] = aggregates['total_sess'] or 0
        context['total_violations'] = aggregates['total_viol'] or 0
        
        daily_stats = records.values('date').annotate(
            rev=Sum('total_revenue'),
            sess=Sum('total_sessions')
        ).order_by('date')
        
        chart_labels = [stat['date'].strftime('%Y-%m-%d') for stat in daily_stats]
        chart_revenue = [float(stat['rev'] or 0) for stat in daily_stats]
        chart_sessions = [int(stat['sess'] or 0) for stat in daily_stats]
        
        context['chart_labels'] = json.dumps(chart_labels)
        context['chart_revenue'] = json.dumps(chart_revenue)
        context['chart_sessions'] = json.dumps(chart_sessions)
        
        top_zones = records.values('zone__name').annotate(
            zone_rev=Sum('total_revenue')
        ).order_by('-zone_rev')[:5]
        
        context['top_zones'] = top_zones
        
        return context

class SystemHealthView(LoginRequiredMixin, AdminRequiredMixin, TemplateView):
    template_name = 'analytics/system_health.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        health_status = check_system_health()
        
        context['health'] = health_status
        context['last_checked'] = timezone.now()
        
        return context
