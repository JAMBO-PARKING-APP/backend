from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.views.generic import TemplateView, View, ListView, DetailView, CreateView, UpdateView, DeleteView
from django.contrib import messages
from django.utils.translation import gettext as _
from django.urls import reverse_lazy
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q, Count, Sum
from django.utils import timezone
from datetime import datetime, timedelta
import json
from apps.common.constants import UserRole, CURRENCY_SYMBOLS, DEFAULT_CURRENCY, ParkingStatus, TransactionStatus
from apps.common.utils import truncate_coord, get_user_local_time
from .models import Country, SystemConfiguration, RegionalModel
from apps.accounts.models import User, Vehicle
from apps.parking.models import Zone, ParkingSlot, ParkingSession, Reservation
from apps.payments.models import Transaction, PaymentMethod, Refund, Invoice, WalletTransaction, PaymentGatewayConfig
from apps.enforcement.models import Violation, OfficerLog, OfficerStatus, QRCodeScan
from apps.rewards.models import LoyaltyAccount, PointTransaction
from apps.notifications.models import NotificationEvent, ChatConversation, ChatMessage

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_country_config(request, country_code):
    """
    Get payment and currency configuration for a specific country
    """
    try:
        from apps.common.models import Country, CountryConfig
        country = Country.objects.get(iso_code=country_code.upper(), is_active=True)
        
        try:
            config = CountryConfig.objects.get(country=country, is_active=True)
            payment_methods = config.payment_methods
            exchange_rate = str(config.exchange_rate_to_base)
        except CountryConfig.DoesNotExist:
            payment_methods = ['wallet']
            if country.iso_code == 'UG':
                payment_methods.append('pesapal')
            exchange_rate = '1.0000'
        
        return Response({
            'country_code': country.iso_code,
            'country_name': country.name,
            'currency_code': country.currency,
            'currency_symbol': country.currency_symbol,
            'payment_methods': payment_methods,
            'exchange_rate': exchange_rate,
        }, status=status.HTTP_200_OK)
        
    except Country.DoesNotExist:
        return Response({
            'error': f'Country with code {country_code} not found'
        }, status=status.HTTP_404_NOT_FOUND)

@login_required
def dashboard_legacy(request):
    """
    Legacy dashboard redirect
    """
    return redirect('dashboard')

@login_required
def placeholder_view(request, feature_name=None):
    """
    Placeholder view for unimplemented features
    """
    context = {
        'page_title': feature_name or 'Feature',
        'feature_name': feature_name or 'This feature',
    }
    return render(request, 'base/placeholder.html', context)

class AdminRequiredMixin(UserPassesTestMixin):
    def test_func(self):
        return self.request.user.is_authenticated and self.request.user.role in [UserRole.ADMIN, UserRole.OFFICER]

class DashboardView(LoginRequiredMixin, TemplateView):
    template_name = 'dashboard/index.html'
    login_url = '/login/'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        config = SystemConfiguration.get_config()
        
        selected_country_id = self.request.session.get('selected_country_id')
        if selected_country_id:
            try:
                country = Country.objects.get(id=selected_country_id)
                currency_symbol = country.currency_symbol or country.currency
            except Country.DoesNotExist:
                currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
        else:
            currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
        
        today = timezone.now().date()
        today_revenue = Transaction.objects.filter(
            created_at__date=today,
            status='completed'
        ).aggregate(total=Sum('amount'))['total'] or 0
        revenue_data = []
        revenue_labels = []
        for i in range(6, -1, -1):
            date = today - timedelta(days=i)
            revenue = Transaction.objects.filter(
                created_at__date=date,
                status='completed'
            ).aggregate(total=Sum('amount'))['total'] or 0
            revenue_data.append(float(revenue))
            revenue_labels.append(date.strftime('%m/%d'))
        zones = Zone.objects.filter(is_active=True)
        occupancy_labels = []
        occupancy_data = []
        
        total_slots_across_zones = 0
        occupied_slots_across_zones = 0

        for zone in zones[:5]:  
            total_slots = zone.slots.count()
            if total_slots > 0:
                occupied = zone.slots.filter(status='occupied').count()
                occupancy_labels.append(zone.name)
                occupancy_data.append(occupied)

        for zone in zones:
            total_slots_across_zones += zone.slots.count()
            occupied_slots_across_zones += zone.slots.filter(status='occupied').count()
            
        average_occupancy = (occupied_slots_across_zones / total_slots_across_zones * 100) if total_slots_across_zones > 0 else 0
        
        context.update({
            'total_users': User.objects.count(),
            'active_sessions': ParkingSession.objects.filter(status=ParkingStatus.ACTIVE).count(),
            'total_zones': Zone.objects.filter(is_active=True).count(),
            'total_violations': Violation.objects.filter(is_paid=False).count(),
            'today_revenue': today_revenue,
            'average_occupancy': average_occupancy,
            'currency_symbol': currency_symbol,
            'recent_sessions': ParkingSession.objects.select_related('vehicle', 'zone').order_by('-created_at')[:5],
            'recent_violations': Violation.objects.select_related('vehicle', 'officer').order_by('-created_at')[:5],
            'revenue_data': revenue_data,
            'revenue_labels': revenue_labels,
            'occupancy_data': occupancy_data,
            'occupancy_labels': occupancy_labels,
            'occupancy_stats': zip(occupancy_labels, occupancy_data),  # For template iteration
        })
        
        return context

class LoginView(View):
    def get(self, request):
        if request.user.is_authenticated:
            return redirect('dashboard')
        return render(request, 'auth/login.html')

    def post(self, request):
        username = request.POST.get('username')
        password = request.POST.get('password')
        
        user = authenticate(request, username=username, password=password)
        if user and user.role in [UserRole.ADMIN, UserRole.OFFICER]:
            login(request, user)
            return redirect('dashboard')
        
        messages.error(request, _('Invalid credentials or insufficient permissions'))
        return render(request, 'auth/login.html')

class LogoutView(View):
    def post(self, request):
        logout(request)
        return redirect('login')

class SwitchCountryView(AdminRequiredMixin, View):
    """View for superusers to switch their regional context manually."""
    def post(self, request):
        country_id = request.POST.get('country_id')
        if country_id:
            request.session['selected_country_id'] = country_id
            messages.success(request, _("Regional context updated successfully."))
        else:
            if 'selected_country_id' in request.session:
                del request.session['selected_country_id']
            messages.info(request, _("Default regional context restored."))
        
        next_url = request.POST.get('next', 'dashboard')
        return redirect(next_url)

class UserListView(AdminRequiredMixin, ListView):
    model = User
    template_name = 'users/list.html'
    context_object_name = 'users'
    paginate_by = 20

    def get_queryset(self):
        queryset = User.objects.all()
        
        # Apply Role Filter
        role = self.request.GET.get('role')
        if role:
            queryset = queryset.filter(role=role)
            
        # Apply Country Filter
        selected_country_id = self.request.session.get('selected_country_id')
        if selected_country_id:
            queryset = queryset.filter(country_id=selected_country_id)
            
        search = self.request.GET.get('search')
        if search:
            queryset = queryset.filter(
                Q(first_name__icontains=search) | 
                Q(last_name__icontains=search) | 
                Q(phone__icontains=search)
            )
        return queryset.order_by('-created_at')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        
        # Handle Currency Formatting based on filter
        selected_country_id = self.request.session.get('selected_country_id')
        if selected_country_id:
            try:
                country = Country.objects.get(id=selected_country_id)
                currency_symbol = country.currency_symbol or country.currency
            except Country.DoesNotExist:
                config = SystemConfiguration.get_config()
                currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
        else:
            config = SystemConfiguration.get_config()
            currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
            
        context['currency_symbol'] = currency_symbol
        return context

class UserCreateView(AdminRequiredMixin, CreateView):
    model = User
    template_name = 'users/form.html'
    fields = ['phone', 'email', 'first_name', 'last_name', 'role', 'is_active']
    success_url = reverse_lazy('user-list')

class UserUpdateView(AdminRequiredMixin, UpdateView):
    model = User
    template_name = 'users/form.html'
    fields = ['phone', 'email', 'first_name', 'last_name', 'role', 'is_active']
    success_url = reverse_lazy('user-list')

class VehicleListView(AdminRequiredMixin, ListView):
    model = Vehicle
    template_name = 'vehicles/list.html'
    context_object_name = 'vehicles'
    paginate_by = 20

    def get_queryset(self):
        queryset = Vehicle.objects.select_related('user').prefetch_related(
            'parking_sessions', 'violations'
        ).all()
        search = self.request.GET.get('search')
        if search:
            queryset = queryset.filter(
                Q(license_plate__icontains=search) |
                Q(user__first_name__icontains=search) |
                Q(user__last_name__icontains=search) |
                Q(make__icontains=search) |
                Q(model__icontains=search)
            )
        return queryset.order_by('-created_at')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['users'] = User.objects.filter(role='driver', is_active=True).order_by('first_name')
        return context

class VehicleDetailView(AdminRequiredMixin, TemplateView):
    template_name = 'vehicles/detail.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        vehicle = get_object_or_404(Vehicle, pk=kwargs['pk'])
        
        parking_sessions = ParkingSession.objects.filter(
            vehicle=vehicle
        ).select_related('zone', 'parking_slot').order_by('-created_at')
        
        violations = Violation.objects.filter(
            vehicle=vehicle
        ).select_related('officer', 'zone').order_by('-created_at')
        
        transactions = Transaction.objects.filter(
            parking_session__vehicle=vehicle
        ).select_related('parking_session', 'payment_method').order_by('-created_at')
        
        total_sessions = parking_sessions.count()
        active_sessions = parking_sessions.filter(status=ParkingStatus.ACTIVE).count()
        completed_sessions = parking_sessions.filter(status=ParkingStatus.COMPLETED).count()
        total_violations = violations.count()
        unpaid_violations = violations.filter(is_paid=False).count()
        total_spent = transactions.filter(
            status='completed'
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        current_session = parking_sessions.filter(status=ParkingStatus.ACTIVE).first()
        
        config = SystemConfiguration.get_config()
        currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
        
        context.update({
            'vehicle': vehicle,
            'parking_sessions': parking_sessions[:10],  
            'violations': violations[:10],  
            'transactions': transactions[:10],  
            'total_sessions': total_sessions,
            'active_sessions': active_sessions,
            'completed_sessions': completed_sessions,
            'total_violations': total_violations,
            'unpaid_violations': unpaid_violations,
            'total_spent': total_spent,
            'current_session': current_session,
            'currency_symbol': currency_symbol,
        })
        
        return context

class ZoneListView(AdminRequiredMixin, ListView):
    model = Zone
    template_name = 'zones/list.html'
    context_object_name = 'zones'
    paginate_by = 20
    
    def get_queryset(self):
        return Zone.objects.select_related().prefetch_related('slots').all().order_by('-created_at')
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        zones = context['zones']
        for zone in zones:
            zone.total_capacity = zone.total_slots if zone.total_slots > 0 else 50
            zone.calculated_occupancy_rate = (zone.active_sessions_count * 100) // zone.total_capacity if zone.total_capacity > 0 else 0
        
        return context

class ZoneDetailView(AdminRequiredMixin, DetailView):
    model = Zone
    template_name = 'zones/detail.html'
    context_object_name = 'zone'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        zone = self.object
        active_sessions = ParkingSession.objects.filter(
            zone=zone,
            status=ParkingStatus.ACTIVE
        ).select_related('vehicle', 'parking_slot').order_by('-start_time')

        recent_sessions = ParkingSession.objects.filter(
            zone=zone,
            status=ParkingStatus.COMPLETED
        ).select_related('vehicle', 'parking_slot').order_by('-actual_end_time')[:10]

        recent_violations = Violation.objects.filter(
            zone=zone
        ).select_related('vehicle', 'officer').order_by('-created_at')[:10]

        total_slots = zone.slots.count() or zone.total_slots or 50
        occupied_slots = active_sessions.count()
        available_slots = max(0, total_slots - occupied_slots)
        occupancy_rate = (occupied_slots / total_slots * 100) if total_slots > 0 else 0

        today = timezone.now().date()
        today_revenue = Transaction.objects.filter(
            parking_session__zone=zone,
            created_at__date=today,
            status='completed'
        ).aggregate(total=Sum('amount'))['total'] or 0

        config = SystemConfiguration.get_config()
        currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
        
        context.update({
            'active_sessions': active_sessions,
            'recent_sessions': recent_sessions,
            'recent_violations': recent_violations,
            'total_slots_count': total_slots,
            'occupied_count': occupied_slots,
            'available_count': available_slots,
            'occupancy_rate': occupancy_rate,
            'today_revenue': today_revenue,
            'currency_symbol': currency_symbol,
        })
        
        return context

class ZoneCreateView(AdminRequiredMixin, CreateView):
    model = Zone
    template_name = 'zones/form.html'
    fields = ['name', 'description', 'hourly_rate', 'max_duration_hours', 'total_slots', 'latitude', 'longitude', 
             'radius_meters', 'zone_image', 'diagram_image', 'diagram_width', 'diagram_height', 'is_active']
    success_url = reverse_lazy('zone-list')
    
    def form_valid(self, form):
        response = super().form_valid(form)
        zone = self.object
        total_slots = zone.total_slots
        
        if total_slots > 0:
            slots_per_row = 10
            slot_width = 50
            slot_height = 50
            
            for i in range(total_slots):
                row = i // slots_per_row
                col = i % slots_per_row
                
                ParkingSlot.objects.create(
                    zone=zone,
                    slot_code=f"S{i+1:03d}",
                    diagram_x=col * slot_width,
                    diagram_y=row * slot_height,
                    diagram_width=40,
                    diagram_height=40,
                    slot_type='regular',
                    status='available'
                )
        
        messages.success(self.request, _('Zone "%(name)s" created with %(count)d parking slots!') % {'name': zone.name, 'count': total_slots})
        return response

class ZoneMapView(AdminRequiredMixin, TemplateView):
    template_name = 'zones/map.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        zones = Zone.objects.filter(is_active=True)
        zones_data = []
        for zone in zones:
            active_sessions = ParkingSession.objects.filter(zone=zone, status=ParkingStatus.ACTIVE)
            total_slots = zone.slots.count() or 50
            occupied_slots = active_sessions.count()
            
            zones_data.append({
                'id': str(zone.id),
                'name': zone.name,
                'latitude': float(zone.latitude) if zone.latitude else 40.7128,
                'longitude': float(zone.longitude) if zone.longitude else -74.0060,
                'total_slots': total_slots,
                'occupied_slots': occupied_slots,
                'is_active': zone.is_active,
                'hourly_rate': float(zone.hourly_rate)
            })
        
        import json
        context['zones_data'] = json.dumps(zones_data)
        return context

class ZoneUpdateView(AdminRequiredMixin, UpdateView):
    model = Zone
    template_name = 'zones/form.html'
    fields = ['name', 'description', 'hourly_rate', 'max_duration_hours', 'total_slots', 'latitude', 'longitude', 
             'radius_meters', 'zone_image', 'diagram_image', 'diagram_width', 'diagram_height', 'is_active']
    success_url = reverse_lazy('zone-list')
    
    def form_valid(self, form):
        old_total = self.object.slots.count()
        new_total = form.cleaned_data['total_slots']
        
        response = super().form_valid(form)
        zone = self.object
        if new_total > old_total:
            slots_per_row = 10
            slot_width = 50
            slot_height = 50
            
            for i in range(old_total, new_total):
                row = i // slots_per_row
                col = i % slots_per_row
                
                ParkingSlot.objects.create(
                    zone=zone,
                    slot_code=f"S{i+1:03d}",
                    diagram_x=col * slot_width,
                    diagram_y=row * slot_height,
                    diagram_width=40,
                    diagram_height=40,
                    slot_type='regular',
                    status='available'
                )
            messages.success(self.request, _('Added %(count)d new parking slots!') % {'count': new_total - old_total})
        elif new_total < old_total:
            excess_slots = zone.slots.filter(status='available').order_by('-created_at')[:old_total - new_total]
            deleted_count = excess_slots.count()
            excess_slots.delete()
            messages.warning(self.request, _('Removed %(count)d available parking slots.') % {'count': deleted_count})
        
        return response

class ZoneDiagramView(AdminRequiredMixin, TemplateView):
    template_name = 'zones/diagram.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        zone = get_object_or_404(Zone, pk=kwargs['pk'])
        slots = zone.slots.all()
        active_sessions = ParkingSession.objects.filter(
            zone=zone,
            status=ParkingStatus.ACTIVE
        ).select_related('vehicle', 'parking_slot')
        occupied_slots = {session.parking_slot_id: session for session in active_sessions if session.parking_slot_id}
        for slot in slots:
            if slot.id in occupied_slots:
                slot.current_status = 'occupied'
                slot.current_vehicle = occupied_slots[slot.id].vehicle.license_plate
            else:
                slot.current_status = 'available'
                slot.current_vehicle = None
        try:
            boundaries = zone.boundaries.all()
        except:
            boundaries = []
        
        try:
            entrances = zone.entrances.all()
        except:
            entrances = []
        
        try:
            drive_paths = zone.drive_paths.all()
        except:
            drive_paths = []
        
        context.update({
            'zone': zone,
            'slots': slots,
            'boundaries': boundaries,
            'entrances': entrances,
            'drive_paths': drive_paths,
            'active_sessions': active_sessions,
            'occupied_count': len(occupied_slots),
            'available_count': slots.count() - len(occupied_slots)
        })
        return context
class SessionListView(AdminRequiredMixin, ListView):
    model = ParkingSession
    template_name = 'sessions/list.html'
    context_object_name = 'sessions'
    paginate_by = 20

    def get_queryset(self):
        return ParkingSession.objects.select_related('vehicle', 'zone').order_by('-created_at')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        config = SystemConfiguration.get_config()
        context['currency_symbol'] = CURRENCY_SYMBOLS.get(config.currency, '$')
        return context

class PaymentListView(AdminRequiredMixin, ListView):
    model = Transaction
    template_name = 'payments/list.html'
    context_object_name = 'transactions'
    paginate_by = 20

    def get_queryset(self):
        queryset = Transaction.objects.select_related('user', 'parking_session', 'payment_method').order_by('-created_at')
        search = self.request.GET.get('search')
        if search:
            queryset = queryset.filter(
                Q(user__first_name__icontains=search) |
                Q(user__last_name__icontains=search) |
                Q(id__icontains=search)
            )
        
        status = self.request.GET.get('status')
        if status:
            queryset = queryset.filter(status=status)
            
        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        config = SystemConfiguration.get_config()
        
        selected_country_id = self.request.session.get('selected_country_id')
        if selected_country_id:
            try:
                country = Country.objects.get(id=selected_country_id)
                currency_symbol = country.currency_symbol or country.currency
            except Country.DoesNotExist:
                currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
        else:
            currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
        
        today = timezone.now().date()
        today_revenue = Transaction.objects.filter(
            created_at__date=today,
            status='completed'
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        today_transactions = Transaction.objects.filter(created_at__date=today).count()
        
        pending_refunds = Transaction.objects.filter(
            refunds__status='pending'
        ).aggregate(total=Sum('refunds__amount'))['total'] or 0
        
        success_rate = Transaction.objects.filter(
            created_at__date=today
        ).aggregate(
            total=Count('id'),
            successful=Count('id', filter=Q(status='completed'))
        )
        
        if success_rate['total'] > 0:
            success_percentage = (success_rate['successful'] / success_rate['total']) * 100
        else:
            success_percentage = 0
        
        context.update({
            'currency_symbol': currency_symbol,
            'today_revenue': today_revenue,
            'today_transactions': today_transactions,
            'pending_refunds': pending_refunds,
            'success_rate': success_percentage,
        })
        return context
class ViolationListView(AdminRequiredMixin, ListView):
    model = Violation
    template_name = 'violations/list.html'
    context_object_name = 'violations'
    paginate_by = 20

    def get_queryset(self):
        return Violation.objects.select_related('vehicle', 'officer', 'zone').order_by('-created_at')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        config = SystemConfiguration.get_config()
        
        selected_country_id = self.request.session.get('selected_country_id')
        if selected_country_id:
            try:
                country = Country.objects.get(id=selected_country_id)
                currency_symbol = country.currency_symbol or country.currency
            except Country.DoesNotExist:
                currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
        else:
            currency_symbol = CURRENCY_SYMBOLS.get(config.currency, '$')
        
        unpaid_violations = Violation.objects.filter(is_paid=False).count()
        paid_today = Violation.objects.filter(
            paid_at__date=timezone.now().date()
        ).count()
        this_month = Violation.objects.filter(
            created_at__month=timezone.now().month
        ).count()
        total_revenue = Violation.objects.filter(
            is_paid=True
        ).aggregate(total=Sum('fine_amount'))['total'] or 0
        
        context.update({
            'currency_symbol': currency_symbol,
            'unpaid_violations': unpaid_violations,
            'paid_today': paid_today,
            'this_month': this_month,
            'total_revenue': total_revenue,
        })
        return context

class CheckPlateAjaxView(AdminRequiredMixin, View):
    def get(self, request):
        plate = request.GET.get('plate', '').strip()
        if not plate:
            return JsonResponse({'error': _('Plate number required')}, status=400)
        
        try:
            vehicle = Vehicle.objects.get(license_plate__iexact=plate, is_active=True)
            active_session = ParkingSession.objects.filter(
                vehicle=vehicle, status=ParkingStatus.ACTIVE
            ).select_related('zone').first()
            
            data = {
                'vehicle': {
                    'license_plate': vehicle.license_plate,
                    'owner': vehicle.user.full_name,
                    'make': vehicle.make,
                    'model': vehicle.model,
                    'color': vehicle.color
                },
                'active_session': None,
                'violations_count': vehicle.violations.filter(is_paid=False).count()
            }
            
            if active_session:
                is_expired = timezone.now() > active_session.planned_end_time
                local_start = get_user_local_time(vehicle.user, active_session.start_time)
                local_end = get_user_local_time(vehicle.user, active_session.planned_end_time)
                
                data['active_session'] = {
                    'zone': active_session.zone.name,
                    'start_time': local_start.strftime('%Y-%m-%d %H:%M'),
                    'planned_end': local_end.strftime('%Y-%m-%d %H:%M'),
                    'is_expired': is_expired,
                    'duration_minutes': active_session.duration_minutes
                }
            
            return JsonResponse(data)
            
        except Vehicle.DoesNotExist:
            return JsonResponse({'error': _('Vehicle not found')}, status=404)

class TerminateSessionAjaxView(AdminRequiredMixin, View):
    """
    Admin-only AJAX view to terminate any parking session
    """
    def post(self, request, session_id):
        try:
            session = get_object_or_404(ParkingSession, pk=session_id)
            if session.status != ParkingStatus.ACTIVE:
                return JsonResponse({'error': _('Session is not active')}, status=400)
            
            session.end_session()
            
            return JsonResponse({
                'success': True,
                'message': _('Session for plate %(plate)s terminated successfully.') % {'plate': session.vehicle.license_plate}
            })
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)

class ZoneLiveStatusAjaxView(AdminRequiredMixin, View):
    def get(self, request, zone_id):
        try:
            zone = Zone.objects.get(pk=zone_id)
            active_sessions = ParkingSession.objects.filter(
                zone=zone,
                status=ParkingStatus.ACTIVE
            ).select_related('vehicle', 'parking_slot')

            all_slots = zone.slots.all()

            slots_data = []
            occupied_slots = {session.parking_slot_id: session for session in active_sessions if session.parking_slot_id}
            
            for slot in all_slots:
                if slot.id in occupied_slots:
                    session = occupied_slots[slot.id]
                    slots_data.append({
                        'id': slot.slot_code or str(slot.id),
                        'status': 'occupied',
                        'vehicle': session.vehicle.license_plate
                    })
                else:
                    slots_data.append({
                        'id': slot.slot_code or str(slot.id),
                        'status': 'available',
                        'vehicle': None
                    })
            
            if not all_slots.exists():
                total_slots = min(100, max(50, active_sessions.count() * 2))
                slots_data = []
                
                for i in range(1, total_slots + 1):
                    if i <= active_sessions.count():
                        session = list(active_sessions)[i-1]
                        slots_data.append({
                            'id': f'S{i:02d}',
                            'status': 'occupied',
                            'vehicle': session.vehicle.license_plate
                        })
                    else:
                        slots_data.append({
                            'id': f'S{i:02d}',
                            'status': 'available',
                            'vehicle': None
                        })
            
            active_sessions_list = []
            for session in active_sessions:
                duration = timezone.now() - session.start_time
                hours, remainder = divmod(duration.total_seconds(), 3600)
                minutes, _ = divmod(remainder, 60)
                
                local_start = get_user_local_time(session.vehicle.user, session.start_time)
                
                active_sessions_list.append({
                    'vehicle': session.vehicle.license_plate,
                    'slot': session.parking_slot.slot_code if session.parking_slot else 'N/A',
                    'start_time': local_start.strftime('%H:%M'),
                    'duration': f"{int(hours)}h {int(minutes)}m" if hours > 0 else f"{int(minutes)}m"
                })
            
            occupied_count = len([s for s in slots_data if s['status'] == 'occupied'])
            total_slots_count = len(slots_data)
            
            data = {
                'zone_name': zone.name,
                'total_slots': total_slots_count,
                'occupied_slots': occupied_count,
                'active_sessions': active_sessions.count(),
                'slots': slots_data,
                'active_sessions_list': active_sessions_list
            }
            
            return JsonResponse(data)
            
        except Zone.DoesNotExist:
            return JsonResponse({'error': _('Zone not found')}, status=404)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)

class UserSearchAjaxView(AdminRequiredMixin, View):
    def get(self, request):
        query = request.GET.get('q', '').strip()
        users = User.objects.filter(
            Q(first_name__icontains=query) |
            Q(last_name__icontains=query) |
            Q(phone__icontains=query),
            role='driver',
            is_active=True
        )[:10]
        
        results = [{
            'id': user.id,
            'text': f"{user.full_name} ({user.phone})"
        } for user in users]
        
        return JsonResponse({'results': results})

class VehicleByPlateAjaxView(AdminRequiredMixin, View):
    def get(self, request):
        plate = request.GET.get('plate', '').strip()
        if not plate:
            return JsonResponse({'error': _('Plate number required')}, status=400)
        
        try:
            vehicle = Vehicle.objects.get(license_plate__iexact=plate, is_active=True)
            return JsonResponse({
                'vehicle_id': str(vehicle.id),
                'license_plate': vehicle.license_plate,
                'owner': vehicle.user.full_name,
                'make': vehicle.make,
                'model': vehicle.model,
                'color': vehicle.color
            })
        except Vehicle.DoesNotExist:
            return JsonResponse({'error': _('Vehicle not found')}, status=404)

class SlotCreateAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        zone_id = request.POST.get('zone_id')
        slot_code = request.POST.get('slot_code')
        x = int(request.POST.get('x', 0))
        y = int(request.POST.get('y', 0))
        slot_type = request.POST.get('slot_type', 'regular')
        rotation = int(request.POST.get('rotation', 0))
        
        try:
            zone = Zone.objects.get(pk=zone_id)
            slot = ParkingSlot.objects.create(
                zone=zone,
                slot_code=slot_code,
                diagram_x=x,
                diagram_y=y,
                slot_type=slot_type,
                diagram_rotation=rotation
            )
            
            return JsonResponse({
                'success': True,
                'slot': {
                    'id': str(slot.id),
                    'code': slot.slot_code,
                    'x': slot.diagram_x,
                    'y': slot.diagram_y,
                    'type': slot.slot_type,
                    'rotation': slot.diagram_rotation,
                    'status': slot.status
                }
            })
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class SlotDeleteAllAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        zone_id = request.POST.get('zone_id')
        if not zone_id:
            return JsonResponse({'error': _('Zone ID is required')}, status=400)
            
        try:
            zone = Zone.objects.get(pk=zone_id)
            # Delete all unoccupied slots in this zone
            # We don't delete occupied slots as they are currently in use
            deleted_count, _ = ParkingSlot.objects.filter(
                zone=zone, 
                status='available'
            ).delete()
            
            return JsonResponse({
                'success': True,
                'deleted_count': deleted_count
            })
        except Zone.DoesNotExist:
            return JsonResponse({'error': _('Zone not found')}, status=404)
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class ReservationListView(AdminRequiredMixin, ListView):
    model = Reservation
    template_name = 'reservations/list.html'
    context_object_name = 'reservations'
    paginate_by = 20

    def get_queryset(self):
        queryset = Reservation.objects.select_related('vehicle__user', 'zone', 'parking_slot').all()
        search = self.request.GET.get('search')
        if search:
            queryset = queryset.filter(
                Q(vehicle__license_plate__icontains=search) |
                Q(payment_reference__icontains=search)
            )
        status = self.request.GET.get('status')
        if status:
            queryset = queryset.filter(status=status)
        return queryset.order_by('-created_at')

class RefundListView(AdminRequiredMixin, ListView):
    model = Refund
    template_name = 'payments/refund_list.html'
    context_object_name = 'refunds'
    paginate_by = 20

    def get_queryset(self):
        return Refund.objects.select_related('original_transaction__user').order_by('-created_at')

class InvoiceListView(AdminRequiredMixin, ListView):
    model = Invoice
    template_name = 'payments/invoice_list.html'
    context_object_name = 'invoices'
    paginate_by = 20

    def get_queryset(self):
        return Invoice.objects.select_related('transaction__user').order_by('-created_at')

class WalletTransactionListView(AdminRequiredMixin, ListView):
    model = WalletTransaction
    template_name = 'payments/wallet_list.html'
    context_object_name = 'transactions'
    paginate_by = 20

    def get_queryset(self):
        queryset = WalletTransaction.objects.select_related('user').all()
        user_id = self.request.GET.get('user_id')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        return queryset.order_by('-created_at')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        config = SystemConfiguration.get_config()
        context['currency_symbol'] = CURRENCY_SYMBOLS.get(config.currency, '$')
        return context

class OfficerLogListView(AdminRequiredMixin, ListView):
    model = OfficerLog
    template_name = 'enforcement/log_list.html'
    context_object_name = 'logs'
    paginate_by = 30

    def get_queryset(self):
        return OfficerLog.objects.select_related('officer').order_by('-created_at')

class OfficerStatusListView(AdminRequiredMixin, ListView):
    model = OfficerStatus
    template_name = 'enforcement/officer_status.html'
    context_object_name = 'statuses'

    def get_queryset(self):
        return OfficerStatus.objects.select_related('officer', 'current_zone').all()

class QRCodeScanListView(AdminRequiredMixin, ListView):
    model = QRCodeScan
    template_name = 'enforcement/scan_list.html'
    context_object_name = 'scans'
    paginate_by = 20

    def get_queryset(self):
        return QRCodeScan.objects.select_related('officer', 'parking_session__vehicle').order_by('-created_at')

class LoyaltyAccountListView(AdminRequiredMixin, ListView):
    model = LoyaltyAccount
    template_name = 'rewards/loyalty_list.html'
    context_object_name = 'accounts'
    paginate_by = 20

    def get_queryset(self):
        return LoyaltyAccount.objects.select_related('user').order_by('-balance')

class PointTransactionListView(AdminRequiredMixin, ListView):
    model = PointTransaction
    template_name = 'rewards/point_transactions.html'
    context_object_name = 'transactions'
    paginate_by = 30

    def get_queryset(self):
        return PointTransaction.objects.select_related('account__user').order_by('-created_at')

class NotificationEventListView(AdminRequiredMixin, ListView):
    model = NotificationEvent
    template_name = 'notifications/event_list.html'
    context_object_name = 'events'
    paginate_by = 30

    def get_queryset(self):
        return NotificationEvent.objects.select_related('user').order_by('-created_at')

class ChatConversationListView(AdminRequiredMixin, ListView):
    model = ChatConversation
    template_name = 'notifications/chat_list.html'
    context_object_name = 'conversations'
    paginate_by = 20

    def get_queryset(self):
        return ChatConversation.objects.select_related('user', 'assigned_agent').order_by('-created_at')

class SystemSettingsView(AdminRequiredMixin, TemplateView):
    template_name = 'settings/config.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['config'] = SystemConfiguration.get_config()
        context['gateways'] = PaymentGatewayConfig.objects.all()
        return context

class SlotUpdateAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        slot_id = request.POST.get('slot_id')
        x = int(request.POST.get('x', 0))
        y = int(request.POST.get('y', 0))
        rotation = int(request.POST.get('rotation', 0))
        
        try:
            slot = ParkingSlot.objects.get(pk=slot_id)
            slot.diagram_x = x
            slot.diagram_y = y
            slot.diagram_rotation = rotation
            slot.save()
            
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class SlotDeleteAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        slot_id = request.POST.get('slot_id')
        
        try:
            slot = ParkingSlot.objects.get(pk=slot_id)
            slot.delete()
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class SlotDeleteAllAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        zone_id = request.POST.get('zone_id')
        
        try:
            zone = Zone.objects.get(pk=zone_id)
            deleted_count = zone.slots.filter(status='available').delete()[0]
            return JsonResponse({'success': True, 'deleted_count': deleted_count})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class BoundaryCreateAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        import json
        zone_id = request.POST.get('zone_id')
        name = request.POST.get('name')
        points = json.loads(request.POST.get('points', '[]'))
        boundary_type = request.POST.get('boundary_type', 'outer')
        color = request.POST.get('color', '#007bff')
        
        try:
            from apps.parking.models import ZoneBoundary
            zone = Zone.objects.get(pk=zone_id)
            boundary = ZoneBoundary.objects.create(
                zone=zone,
                name=name,
                points=points,
                boundary_type=boundary_type,
                color=color
            )
            
            return JsonResponse({
                'success': True,
                'boundary': {
                    'id': str(boundary.id),
                    'name': boundary.name,
                    'points': boundary.points,
                    'type': boundary.boundary_type,
                    'color': boundary.color
                }
            })
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class EntranceCreateAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        zone_id = request.POST.get('zone_id')
        name = request.POST.get('name')
        x = int(request.POST.get('x', 0))
        y = int(request.POST.get('y', 0))
        entrance_type = request.POST.get('entrance_type', 'both')
        
        try:
            from apps.parking.models import ZoneEntrance
            zone = Zone.objects.get(pk=zone_id)
            entrance = ZoneEntrance.objects.create(
                zone=zone,
                name=name,
                diagram_x=x,
                diagram_y=y,
                entrance_type=entrance_type
            )
            
            return JsonResponse({
                'success': True,
                'entrance': {
                    'id': str(entrance.id),
                    'name': entrance.name,
                    'x': entrance.diagram_x,
                    'y': entrance.diagram_y,
                    'type': entrance.entrance_type
                }
            })
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class DrivePathCreateAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        import json
        zone_id = request.POST.get('zone_id')
        name = request.POST.get('name')
        points = json.loads(request.POST.get('points', '[]'))
        path_type = request.POST.get('path_type', 'main')
        color = request.POST.get('color', '#6c757d')
        
        try:
            from apps.parking.models import DrivePath
            zone = Zone.objects.get(pk=zone_id)
            drive_path = DrivePath.objects.create(
                zone=zone,
                name=name,
                points=points,
                path_type=path_type,
                color=color
            )
            
            return JsonResponse({
                'success': True,
                'drive_path': {
                    'id': str(drive_path.id),
                    'name': drive_path.name,
                    'points': drive_path.points,
                    'type': drive_path.path_type,
                    'color': drive_path.color
                }
            })
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})
            
class BoundaryUpdateAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        import json
        boundary_id = request.POST.get('boundary_id')
        points = json.loads(request.POST.get('points', '[]'))
        
        try:
            from apps.parking.models import ZoneBoundary
            boundary = ZoneBoundary.objects.get(pk=boundary_id)
            boundary.points = points
            boundary.save()
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class BoundaryDeleteAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        boundary_id = request.POST.get('boundary_id')
        
        try:
            from apps.parking.models import ZoneBoundary
            boundary = ZoneBoundary.objects.get(pk=boundary_id)
            boundary.delete()
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class DrivePathUpdateAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        import json
        path_id = request.POST.get('path_id')
        points = json.loads(request.POST.get('points', '[]'))
        
        try:
            from apps.parking.models import DrivePath
            drive_path = DrivePath.objects.get(pk=path_id)
            drive_path.points = points
            drive_path.save()
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class DrivePathDeleteAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        path_id = request.POST.get('path_id')
        
        try:
            from apps.parking.models import DrivePath
            drive_path = DrivePath.objects.get(pk=path_id)
            drive_path.delete()
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

class EntranceDeleteAjaxView(AdminRequiredMixin, View):
    def post(self, request):
        entrance_id = request.POST.get('entrance_id')
        
        try:
            from apps.parking.models import ZoneEntrance
            entrance = ZoneEntrance.objects.get(pk=entrance_id)
            entrance.delete()
            return JsonResponse({'success': True})
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})