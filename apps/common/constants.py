from django.db import models
from django.utils.translation import gettext_lazy as _

class UserRole(models.TextChoices):
    DRIVER = 'driver', _('Driver')
    OFFICER = 'officer', _('Officer')
    ADMIN = 'admin', _('Admin')

class ParkingStatus(models.TextChoices):
    ACTIVE = 'active', _('Active')
    COMPLETED = 'completed', _('Completed')
    EXPIRED = 'expired', _('Expired')
    CANCELLED = 'cancelled', _('Cancelled')

class SlotStatus(models.TextChoices):
    AVAILABLE = 'available', _('Available')
    OCCUPIED = 'occupied', _('Occupied')
    RESERVED = 'reserved', _('Reserved')
    DISABLED = 'disabled', _('Disabled')

class TransactionStatus(models.TextChoices):
    PENDING = 'pending', _('Pending')
    COMPLETED = 'completed', _('Completed')
    FAILED = 'failed', _('Failed')
    REFUNDED = 'refunded', _('Refunded')

class ViolationType(models.TextChoices):
    EXPIRED = 'expired', _('Expired Parking')
    NO_PAYMENT = 'no_payment', _('No Payment')
    WRONG_ZONE = 'wrong_zone', _('Wrong Zone')
    DISABLED_SPOT = 'disabled_spot', _('Disabled Spot Violation')

class Currency(models.TextChoices):
    USD = 'USD', _('US Dollar ($)')
    EUR = 'EUR', _('Euro (€)')
    GBP = 'GBP', _('British Pound (£)')
    CAD = 'CAD', _('Canadian Dollar (C$)')
    AUD = 'AUD', _('Australian Dollar (A$)')
    UGX = 'UGX', _('Uganda Shilling (UGX)')
    KES = 'KES', _('Kenya Shilling (Ksh)')
    GHS = 'GHS', _('Ghana Cedi (₵)')

# Currency symbols mapping
CURRENCY_SYMBOLS = {
    'USD': '$',
    'EUR': '€',
    'GBP': '£',
    'CAD': 'C$',
    'AUD': 'A$',
    'UGX': 'UGX',
    'KES': 'Ksh',
    'GHS': '₵',

}

# Default system currency
DEFAULT_CURRENCY = 'UGX'