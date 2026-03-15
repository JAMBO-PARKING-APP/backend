import random
import string
import logging
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.conf import settings
from django.core.mail import EmailMessage
from django.db import transaction

# Late imports inside functions to avoid circularity if possible, 
# but we need the model name for the receiver string.

logger = logging.getLogger(__name__)


def generate_temp_password(length=12):
    chars = string.ascii_letters + string.digits + "!@#$"
    return ''.join(random.choices(chars, k=length))


def _process_approval(instance_pk):
    """
    Runs AFTER the admin transaction commits (via on_commit).
    The password is already stored on the model by admin's save_model — we just read it here.
    """
    from apps.zone_owner_portal.models import ZoneApplicationPublic

    try:
        instance = ZoneApplicationPublic.objects.get(pk=instance_pk)
    except ZoneApplicationPublic.DoesNotExist:
        return

    if instance.status != 'approved':
        return

    # Already has a zone linked — nothing left to do
    if instance.created_zone_id:
        return

    from apps.accounts.models import User
    from apps.parking.models import Zone, ZoneType

    # Use the password already generated and stored by admin's save_model
    temp_password = instance.demo_password or generate_temp_password()

    # Lowercase email for comparison
    applicant_email = instance.applicant_email.strip().lower()

    # Proper phone normalization using phonenumbers before lookup
    phone_str = instance.applicant_phone.strip()
    try:
        import phonenumbers
        from django.conf import settings
        default_region = getattr(settings, 'PHONENUMBER_DEFAULT_REGION', 'GH')
        parsed = phonenumbers.parse(phone_str, default_region)
        if phonenumbers.is_valid_number(parsed):
            phone = phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)
        else:
            if not phone_str.startswith('+'):
                if phone_str.startswith('0') and default_region == 'GH':
                    phone = '+233' + phone_str.lstrip('0')
                else:
                    phone = '+' + phone_str.lstrip('0')
            else:
                phone = phone_str
    except Exception as pe:
        print(f"DEBUG SIGNAL: Phone parsing error: {pe}")
        phone = phone_str

    # ── 1. Create or locate user ──────────────────────────────
    try:
        from django.db.models import Q
        user = User.objects.filter(Q(email__iexact=applicant_email) | Q(phone=phone)).first()
        
        if not user:
            print(f"DEBUG SIGNAL: No user found for {applicant_email} or {phone}, creating new account...")
            name_parts = instance.applicant_name.strip().split(' ', 1)
            first_name = name_parts[0]
            last_name = name_parts[1] if len(name_parts) > 1 else ''

            from apps.common.constants import UserRole
            user = User(
                phone=phone,
                email=applicant_email,
                first_name=first_name,
                last_name=last_name,
                role=UserRole.ZONE_OWNER,
                is_verified=True,
                is_active=True,
            )
            user.set_password(temp_password)
            user.save()
            print(f"DEBUG SIGNAL: Successfully created user {user.email} with phone {user.phone} and role {user.role}")
            logger.info(f"[ZonePortal] Created user {user.email} for application {instance.application_id}")
        else:
            print(f"DEBUG SIGNAL: User already exists (ID={user.id}, Email={user.email}, Phone={user.phone}), updating if needed.")
            
            update_fields = []
            if not user.email or user.email.lower() != applicant_email:
                user.email = applicant_email
                update_fields.append('email')
                print(f"DEBUG SIGNAL: Backfilled/updated email to {applicant_email}")
                
            from apps.common.constants import UserRole
            if user.role != UserRole.ZONE_OWNER:
                 user.role = UserRole.ZONE_OWNER
                 update_fields.append('role')
                 print(f"DEBUG SIGNAL: Updated role to ZONE_OWNER")
                 
            # Note: We do NOT overwrite the password if the user already exists,
            # as they might actively be using it. However, the email sent WILL 
            # contain the demo password. If this is a real issue, we could conditionally
            # reset it, but it's safer to avoid unrequested password resets.
            
            if update_fields:
                user.save(update_fields=update_fields)
            logger.info(f"[ZonePortal] Using existing user {user.email}")
    except Exception as e:
        print(f"DEBUG SIGNAL ERROR: Failed to create/find user for {applicant_email}: {e}")
        import traceback
        traceback.print_exc()
        logger.error(f"[ZonePortal] Failed to create user for application {instance.application_id}: {e}")
        return

    # ── 1.5 Determine Country from Coordinates ────────────────
    from apps.common.utils import get_country_from_coords
    country = get_country_from_coords(instance.latitude, instance.longitude)
    if country:
        print(f"DEBUG SIGNAL: Mapped coordinates ({instance.latitude}, {instance.longitude}) to country: {country.name}")
    else:
        print(f"DEBUG SIGNAL: Could not map coordinates to a country.")

    # ── 2. Create zone ────────────────────────────────────────
    try:
        zone = Zone(
            name=instance.proposed_name,
            description=f"Private parking zone at {instance.address}",
            latitude=instance.latitude,
            longitude=instance.longitude,
            hourly_rate=instance.proposed_hourly_rate,
            total_slots=instance.total_slots,
            zone_type=ZoneType.PRIVATE,
            owner=user,
            country=country,
            is_active=True,
            commission_rate=10,
        )
        zone.save()

        # Update user country if they don't have one
        if user and not user.country and country:
            user.country = country
            user.save(update_fields=['country'])
            print(f"DEBUG SIGNAL: Set user country to {country.name}")

        # Link zone back; credentials already written by save_model
        ZoneApplicationPublic.objects.filter(pk=instance.pk).update(created_zone=zone)
        logger.info(f"[ZonePortal] Created zone '{zone.name}' (id={zone.id}) mapped to {country.name if country else 'Unknown'}")
    except Exception as e:
        logger.error(f"[ZonePortal] Failed to create zone for application {instance.application_id}: {e}")
        return

    # ── 3. Send welcome email ─────────────────────────────────
    try:
        portal_url = getattr(settings, 'PARTNER_PORTAL_URL', 'http://localhost:5173')
        login_url = f"{portal_url}/login"

        subject = "🎉 Your Parking Space Application Has Been Approved — Space Park"
        cred_block = (
            f'<p style="margin:4px 0;color:#94a3b8;"><strong style="color:#e2e8f0;">Temporary Password:</strong>'
            f' <code style="background:rgba(255,255,255,0.1);padding:2px 8px;border-radius:4px;font-family:monospace;">'
            f'{temp_password}</code></p>'
        ) if temp_password else ''

        html_body = f"""
        <!DOCTYPE html>
        <html>
        <body style="margin:0;padding:0;background:#08081a;font-family:'Segoe UI',sans-serif;color:#e2e8f0;">
          <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 20px;">
            <tr><td align="center">
              <table width="600" cellpadding="0" cellspacing="0" style="background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.08);border-radius:16px;overflow:hidden;">
                <tr>
                  <td style="background:linear-gradient(135deg,#6366f1,#8b5cf6);padding:40px;text-align:center;">
                    <h1 style="margin:0;color:#fff;font-size:28px;font-weight:700;">Space Park</h1>
                    <p style="color:rgba(255,255,255,0.8);margin:8px 0 0;">Partner Portal</p>
                  </td>
                </tr>
                <tr>
                  <td style="padding:40px;">
                    <h2 style="color:#a5b4fc;margin:0 0 16px;">Congratulations, {instance.applicant_name}! 🎊</h2>
                    <p style="color:#94a3b8;line-height:1.7;">Your application for
                      <strong style="color:#e2e8f0;">{instance.proposed_name}</strong>
                      has been <strong style="color:#4ade80;">approved</strong>. Your parking zone is now live on Space Park.</p>

                    <div style="background:rgba(99,102,241,0.1);border:1px solid rgba(99,102,241,0.3);border-radius:12px;padding:24px;margin:24px 0;">
                      <h3 style="margin:0 0 16px;color:#a5b4fc;">🔑 Your Login Credentials</h3>
                      <p style="margin:4px 0;color:#94a3b8;"><strong style="color:#e2e8f0;">Portal URL:</strong>
                        <a href="{login_url}" style="color:#818cf8;">{login_url}</a></p>
                      <p style="margin:4px 0;color:#94a3b8;"><strong style="color:#e2e8f0;">Email:</strong> {instance.applicant_email}</p>
                      {cred_block}
                    </div>

                    <p style="color:#94a3b8;line-height:1.7;">Once logged in, you'll need to add your
                      <strong style="color:#e2e8f0;">bank details</strong> so we can deposit your earnings.
                      You can then monitor your zone's performance, sessions, and revenue in real-time.</p>

                    <a href="{login_url}" style="display:inline-block;background:linear-gradient(135deg,#6366f1,#8b5cf6);
                      color:#fff;text-decoration:none;padding:14px 32px;border-radius:8px;font-weight:600;
                      font-size:16px;margin-top:16px;">Login to Partner Portal →</a>
                  </td>
                </tr>
                <tr>
                  <td style="padding:20px 40px;border-top:1px solid rgba(255,255,255,0.06);text-align:center;">
                    <p style="margin:0;color:#475569;font-size:12px;">© 2026 Space Park Ltd. All rights reserved.</p>
                  </td>
                </tr>
              </table>
            </td></tr>
          </table>
        </body>
        </html>
        """

        email = EmailMessage(
            subject=subject,
            body=html_body,
            from_email=f"Space Park <{settings.DEFAULT_FROM_EMAIL}>",
            to=[instance.applicant_email],
        )
        email.content_subtype = "html"
        email.send(fail_silently=True)
        logger.info(f"[ZonePortal] Welcome email sent to {instance.applicant_email}")
    except Exception as e:
        logger.error(f"[ZonePortal] Failed to send welcome email: {e}")


print("DEBUG SIGNAL: signals.py module loaded and registering handlers")

@receiver(post_save, sender='zone_owner_portal.ZoneApplicationPublic')
def handle_application_approval(sender, instance, created, **kwargs):
    """
    Defers the actual work to after the DB transaction commits,
    preventing TransactionManagementError in the Django admin.
    """
    print(f"DEBUG SIGNAL: Signal received for application {instance.application_id}, status={instance.status}, created={created}")
    if created:
        return
    if instance.status != 'approved':
        return
    if instance.created_zone_id:
        print(f"DEBUG SIGNAL: Application {instance.application_id} already has a zone, skipping.")
        return

    # Schedule after the current atomic block commits — safe from admin transactions
    print(f"DEBUG SIGNAL: Scheduling deferred processing for {instance.application_id}")
    transaction.on_commit(lambda: _process_approval(instance.pk))


# Ensure the model is importable at signal-registration time
from apps.zone_owner_portal.models import ZoneApplicationPublic  # noqa
