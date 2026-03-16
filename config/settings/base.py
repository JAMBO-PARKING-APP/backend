from pathlib import Path
from decouple import config
from celery.schedules import crontab
import django.utils.translation
import sys
import types
import inspect
import builtins

# Python 3.11 compatibility shim for legacy libraries (like django-suit)
if not hasattr(inspect, 'getargspec'):
    inspect.getargspec = inspect.getfullargspec

# Python 3 compatibility for legacy 'basestring'
if not hasattr(builtins, 'basestring'):
    builtins.basestring = str

# Django 4.x compatibility shim for legacy libraries (like django-suit)
if not hasattr(django.utils.translation, 'ugettext'):
    django.utils.translation.ugettext = django.utils.translation.gettext
if not hasattr(django.utils.translation, 'ugettext_lazy'):
    django.utils.translation.ugettext_lazy = django.utils.translation.gettext_lazy
if not hasattr(django.utils.translation, 'ugettext_noop'):
    django.utils.translation.ugettext_noop = django.utils.translation.gettext_noop
if not hasattr(django.utils.translation, 'ungettext'):
    django.utils.translation.ungettext = django.utils.translation.ngettext

# Shim for removed django.utils.six
try:
    import six
    sys.modules['django.utils.six'] = six
except ImportError:
    # Create a minimal six shim if not installed
    six_mod = types.ModuleType('six')
    six_mod.string_types = (str,)
    six_mod.text_type = str
    six_mod.binary_type = bytes
    six_mod.PY3 = True
    sys.modules['six'] = six_mod
    sys.modules['django.utils.six'] = six_mod

# Shim for removed admin_static module in Django 3.0+
try:
    from django.templatetags.static import static
    admin_static_mod = types.ModuleType('django.contrib.admin.templatetags.admin_static')
    admin_static_mod.static = static
    sys.modules['django.contrib.admin.templatetags.admin_static'] = admin_static_mod
except ImportError:
    pass

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = config('SECRET_KEY', default='django-insecure-change-in-production')

DEBUG = config('DEBUG', default=False, cast=bool)

ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1', cast=lambda v: [s.strip() for s in v.split(',')])

CSRF_TRUSTED_ORIGINS = config('CSRF_TRUSTED_ORIGINS', default='http://localhost:8000,http://127.0.0.1:8000', cast=lambda v: [s.strip() for s in v.split(',')])

DJANGO_APPS = [
    'suit',
    'daphne',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
]

THIRD_PARTY_APPS = [
    'channels',
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'phonenumber_field',
    'drf_spectacular',
]

LOCAL_APPS = [
    'apps.common',
    'apps.accounts',
    'apps.parking',
    'apps.payments',
    'apps.enforcement',
    'apps.notifications',
    'apps.analytics',
    'apps.support_chat',
    'apps.rewards',
    'apps.zone_owner_portal.apps.ZoneOwnerPortalConfig',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.locale.LocaleMiddleware', 
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'apps.common.middleware.RegionalContextMiddleware',
    'apps.accounts.middleware.SingleDeviceLoginMiddleware',  
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                'django.template.context_processors.i18n', 
                'apps.common.context_processors.regional_settings',
            ],
            'builtins': [
                'apps.common.templatetags.admin_static',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'
ASGI_APPLICATION = 'config.asgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME', default='smart_parking'),
        'USER': config('DB_USER', default='postgres'),
        'PASSWORD': config('DB_PASSWORD', default='password'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
        'CONN_MAX_AGE': 60,  
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Kampala'
USE_I18N = True
USE_TZ = True

from django.utils.translation import gettext_lazy as _

LANGUAGES = [
    ('en', _('English')),
    ('sw', _('Swahili')),
    ('fr', _('French')),
    ('es', _('Spanish')),
]

LOCALE_PATHS = [
    BASE_DIR / 'locale',
]

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Django Suit Configuration
SUIT_CONFIG = {
    'ADMIN_NAME': 'JAMBO PARKING',
    'HEADER_DATE_FORMAT': 'l, j. F Y',
    'HEADER_TIME_FORMAT': 'H:i',
    'MENU_ICONS': {
        'sites': 'icon-leaf',
        'auth': 'icon-lock',
        'accounts': 'icon-user',
        'parking': 'icon-map-marker',
        'payments': 'icon-shopping-cart',
        'enforcement': 'icon-flag',
        'notifications': 'icon-envelope',
        'analytics': 'icon-signal',
        'rewards': 'icon-gift',
    },
    'MENU_OPEN_FIRST_CHILD': True,
    'MENU': (
        'sites',
        {'app': 'auth', 'icon': 'icon-lock', 'models': ('user', 'group')},
        {'app': 'accounts', 'icon': 'icon-user', 'models': ('user', 'vehicle', 'otpcode')},
        {'app': 'parking', 'icon': 'icon-map-marker', 'models': ('country', 'zone', 'parkingslot', 'parkingsession', 'reservation')},
        {'app': 'payments', 'icon': 'icon-shopping-cart', 'models': ('paymentmethod', 'transaction', 'wallet', 'wallettransaction')},
        {'app': 'enforcement', 'icon': 'icon-flag', 'models': ('violation', 'officerlog', 'officerstatus', 'qrcodescan')},
        {'app': 'notifications', 'icon': 'icon-envelope', 'models': ('notification', 'smstemplate')},
        {'app': 'rewards', 'icon': 'icon-gift', 'models': ('loyaltypoint', 'reward', 'userreward')},
        {'label': 'Zone Owner Portal', 'icon': 'icon-home', 'url': '/admin/zone_owner_portal/'},
    ),
    'LIST_PER_PAGE': 20,
    'LAYOUT': 'vertical',
}

# WhiteNoise settings
WHITENOISE_USE_FINDERS = True
WHITENOISE_AUTOREFRESH = True
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
AUTH_USER_MODEL = 'accounts.User'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'apps.accounts.authentication.DeviceSessionJWTAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/day',
        'user': '1000/hour'
    },
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}

from datetime import timedelta
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=365),  
    'REFRESH_TOKEN_LIFETIME': timedelta(days=365),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': False,
    'UPDATE_LAST_LOGIN': True,
    'JTI_CLAIM': 'jti',  
}

REDIS_URL = config('REDIS_URL', default='redis://localhost:6379/0')

CELERY_BROKER_URL = REDIS_URL
CELERY_RESULT_BACKEND = REDIS_URL
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE

CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            "hosts": [REDIS_URL],
        },
    },
}

SPECTACULAR_SETTINGS = {
    'TITLE': 'JAMBO PARK API',
    'DESCRIPTION': 'Enterprise Intelligent Parking System API documentation.',
    'VERSION': '2.8.0',
    'SERVE_INCLUDE_SCHEMA': False,
    'COMPONENT_SPLIT_PATCH': True,
    'COMPONENT_SPLIT_REQUEST': True,
    'SWAGGER_UI_SETTINGS': {
        'deepLinking': True,
        'persistAuthorization': True,
        'displayOperationId': True,
    },
}

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {'max_connections': 100},
        },
        'KEY_PREFIX': 'jambo_park',
        'TIMEOUT': 300,  
    },
    'zones_cache': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {'max_connections': 100},
        },
        'KEY_PREFIX': 'zones',
        'TIMEOUT': 1800,  
    },
    'help_cache': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {'max_connections': 100},
        },
        'KEY_PREFIX': 'help',
        'TIMEOUT': 86400,  
    }
}

SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'

PHONENUMBER_DEFAULT_REGION = 'GH'

PESAPAL_CONSUMER_KEY = config('PESAPAL_CONSUMER_KEY', default='')
PESAPAL_CONSUMER_SECRET = config('PESAPAL_CONSUMER_SECRET', default='')
PESAPAL_SANDBOX = config('PESAPAL_SANDBOX', default=True, cast=bool)
PESAPAL_CALLBACK_URL = config('PESAPAL_CALLBACK_URL', default='https://curtis-unmobilized-clarence.ngrok-free.dev/api/user/payments/pesapal/callback/')
PESAPAL_IPN_ID = config('PESAPAL_IPN_ID', default='')
PESAPAL_USD_EXCHANGE_RATE = config('PESAPAL_USD_EXCHANGE_RATE', default=3700, cast=int)

# Email Settings
EMAIL_BACKEND = config('EMAIL_BACKEND', default='django.core.mail.backends.smtp.EmailBackend')
EMAIL_HOST = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = config('EMAIL_USE_TLS', default=True, cast=bool)
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL', default='union.crm.products@gmail.com')

FIREBASE_CREDENTIALS_PATH = BASE_DIR / 'jambo-parking-d6e88-firebase-adminsdk-fbsvc-9ba12edacb.json'
FIREBASE_ENABLED = config('FIREBASE_ENABLED', default=True, cast=bool)

GOOGLE_API_KEY = config('GOOGLE_API_KEY', default='')

CELERY_BEAT_SCHEDULE = {
    'check-expired-sessions': {
        'task': 'apps.parking.tasks.check_expired_sessions',
        'schedule': crontab(minute='*/1'),  
    },
    'send-session-alerts': {
        'task': 'apps.parking.tasks.send_session_alerts',
        'schedule': crontab(minute='*/1'),  
    },
    'cancel-overdue-reservations': {
        'task': 'apps.parking.tasks.cancel_overdue_reservations',
        'schedule': crontab(minute='*/5'),  
    },
    'notify-exit-overdue': {
        'task': 'apps.parking.tasks.notify_exit_overdue',
        'schedule': crontab(minute='*/5'),  
    },
    'validate-active-session-location': {
        'task': 'apps.parking.tasks.validate_active_session_location',
        'schedule': crontab(minute='*/10'),  
    },
    'identify-violation-hotspots': {
        'task': 'apps.enforcement.tasks.identify_violation_hotspots',
        'schedule': crontab(minute='*/15'),  
    },
    'generate-daily-revenue': {
        'task': 'apps.analytics.tasks.generate_daily_revenue',
        'schedule': crontab(minute=5, hour=0),  
    },
    'check-system-health': {
        'task': 'apps.common.tasks.check_system_health',
        'schedule': crontab(minute=0, hour='*/1'),  
    },
    'update-zone-availability-cache': {
        'task': 'apps.parking.tasks.update_zone_availability_cache',
        'schedule': crontab(minute='*/5'),
    },
    'cleanup-slot-statuses': {
        'task': 'apps.parking.tasks.cleanup_slot_statuses',
        'schedule': crontab(minute='*/10'),
    },
    'escalate-unpaid-violations': {
        'task': 'apps.enforcement.tasks.escalate_unpaid_violations',
        'schedule': crontab(minute=0, hour=0),
    },
    'cleanup-system-data': {
        'task': 'apps.common.tasks.cleanup_system_data',
        'schedule': crontab(minute=0, hour=3, day_of_week=0),  
    },
    'send-weekly-admin-report': {
        'task': 'apps.analytics.reporting_tasks.send_weekly_admin_report',
        'schedule': crontab(minute=0, hour=8, day_of_week=1),  
    },
}