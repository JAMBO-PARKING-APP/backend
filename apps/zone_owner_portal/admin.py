from django.contrib import admin
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _
from .models import ZoneApplicationPublic, OwnerBankDetails, ZoneOwner
from .signals import generate_temp_password
from apps.common.constants import UserRole


def approve_applications(modeladmin, request, queryset):
    """Bulk approve action — generates credentials in the same transaction."""
    count = 0
    for app in queryset.filter(status='pending'):
        # Generate & persist password NOW (same transaction → visible immediately)
        if not app.demo_password:
            app.demo_password = generate_temp_password()
            app.demo_email = app.applicant_email
        app.status = 'approved'
        app.save()   # triggers post_save → on_commit schedules user+zone creation
        count += 1
    modeladmin.message_user(request, f"✅ Approved {count} application(s).")


approve_applications.short_description = "✅ Approve selected applications"


def reject_applications(modeladmin, request, queryset):
    updated = queryset.filter(status='pending').update(status='rejected')
    modeladmin.message_user(request, f"❌ Rejected {updated} application(s).")


reject_applications.short_description = "❌ Reject selected applications"


@admin.register(ZoneApplicationPublic)
class ZoneApplicationPublicAdmin(admin.ModelAdmin):
    list_display = [
        'application_id', 'proposed_name', 'applicant_name', 'applicant_email',
        'applicant_phone', 'total_slots', 'proposed_hourly_rate', 'status', 'created_at',
    ]
    list_filter = ['status', 'parking_surface', 'has_security', 'has_cctv']
    search_fields = ['applicant_name', 'applicant_email', 'proposed_name', 'address']
    readonly_fields = [
        'application_id', 'created_at', 'updated_at', 'created_zone',
        'demo_credentials_display',
    ]
    actions = [approve_applications, reject_applications]

    fieldsets = (
        (_('🔑 Demo Login Credentials'), {
            'fields': ('demo_credentials_display',),
        }),
        (_('Application & Status'), {
            'fields': ('application_id', 'status', 'admin_notes', 'created_zone'),
        }),
        (_('Applicant Details'), {
            'fields': ('applicant_name', 'applicant_email', 'applicant_phone'),
        }),
        (_('Zone Proposal'), {
            'fields': (
                'proposed_name', 'address', 'latitude', 'longitude',
                'total_slots', 'proposed_hourly_rate', 'operating_hours',
                'parking_surface', 'has_security', 'has_cctv', 'access_instructions', 'documents',
            ),
        }),
        (_('Timestamps'), {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def save_model(self, request, obj, form, change):
        """Generate credentials the moment an admin sets status → approved."""
        if change and obj.status == 'approved' and not obj.demo_password:
            obj.demo_password = generate_temp_password()
            obj.demo_email = obj.applicant_email
        super().save_model(request, obj, form, change)

    def demo_credentials_display(self, obj):
        portal_url = 'http://localhost:5173/login'

        if obj.demo_email and obj.demo_password:
            return format_html(
                '''
                <div style="padding:20px 24px;background:linear-gradient(135deg,#1e1b4b,#0f172a);
                    border:2px solid #6366f1;border-radius:12px;max-width:560px;">
                  <div style="font-size:12px;font-weight:700;color:#a5b4fc;text-transform:uppercase;
                      letter-spacing:0.1em;margin-bottom:16px;">🔑 Partner Login Credentials</div>
                  <table style="width:100%;border-collapse:collapse;font-size:14px;">
                    <tr>
                      <td style="padding:7px 0;color:#64748b;width:120px;vertical-align:top;">Portal URL</td>
                      <td style="padding:7px 0;">
                        <a href="{url}" target="_blank"
                           style="color:#818cf8;text-decoration:none;">{url}</a>
                      </td>
                    </tr>
                    <tr>
                      <td style="padding:7px 0;color:#64748b;vertical-align:top;">Email</td>
                      <td style="padding:7px 0;">
                        <code style="background:rgba(99,102,241,0.15);padding:3px 10px;
                            border-radius:6px;color:#e2e8f0;">{email}</code>
                      </td>
                    </tr>
                    <tr>
                      <td style="padding:7px 0;color:#64748b;vertical-align:top;">Password</td>
                      <td style="padding:7px 0;">
                        <code style="background:rgba(74,222,128,0.12);padding:3px 12px;
                            border-radius:6px;color:#4ade80;font-size:15px;font-weight:700;
                            letter-spacing:0.05em;">{pw}</code>
                      </td>
                    </tr>
                  </table>
                  <div style="margin-top:14px;padding:8px 12px;
                      background:rgba(251,191,36,0.08);border:1px solid rgba(251,191,36,0.35);
                      border-radius:6px;font-size:12px;color:#fbbf24;">
                    ⚠️ These credentials were emailed to the applicant. Remind them to change
                    their password after first login.
                  </div>
                </div>
                ''',
                url=portal_url,
                email=obj.demo_email,
                pw=obj.demo_password,
            )

        if obj.status == 'approved':
            return format_html(
                '<div style="padding:12px 16px;background:#1a1a2e;border:1px solid #f59e0b;'
                'border-radius:8px;color:#fbbf24;font-size:13px;">'
                '⏳ Processing… zone and user are being created in the background. '
                'Refresh this page in a few seconds.</div>'
            )

        return format_html(
            '<div style="padding:12px 16px;background:#0f172a;border:1px solid #1e293b;'
            'border-radius:8px;color:#475569;font-size:13px;">'
            'Credentials will appear here once this application is approved.</div>'
        )

    demo_credentials_display.short_description = 'Demo Credentials'


@admin.register(OwnerBankDetails)
class OwnerBankDetailsAdmin(admin.ModelAdmin):
    list_display = ['user', 'bank_name', 'account_number', 'account_holder_name', 'updated_at']
    search_fields = ['user__email', 'bank_name', 'account_number']
    readonly_fields = ['created_at', 'updated_at']

class OwnerBankDetailsInline(admin.StackedInline):
    model = OwnerBankDetails
    can_delete = False
    verbose_name_plural = 'Bank Details'
    classes = ['collapse']

@admin.register(ZoneOwner)
class ZoneOwnerAdmin(admin.ModelAdmin):
    """Specialized admin panel for Partners/Zone Owners"""
    list_display = ('email', 'phone', 'first_name', 'last_name', 'is_active', 'has_bank_details')
    search_fields = ('email', 'phone', 'first_name', 'last_name')
    list_filter = ('is_active',)
    inlines = [OwnerBankDetailsInline]
    
    def get_queryset(self, request):
        return super().get_queryset(request).filter(role=UserRole.ZONE_OWNER)
        
    @admin.display(boolean=True, description='Bank Details Provided')
    def has_bank_details(self, obj):
        return hasattr(obj, 'bank_details')
