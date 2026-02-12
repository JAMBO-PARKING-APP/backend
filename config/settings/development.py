from decouple import config
from .base import *

DEBUG = True

ALLOWED_HOSTS = config('ALLOWED_HOSTS', 
                       default='localhost,127.0.0.1,0.0.0.0,10.0.2.2,b95b-154-227-132-66.ngrok-free.app', 
                       cast=lambda v: [s.strip() for s in v.split(',')])

CSRF_TRUSTED_ORIGINS = config('CSRF_TRUSTED_ORIGINS', 
                             default='http://localhost:8000,http://127.0.0.1:8000', 
                             cast=lambda v: [s.strip() for s in v.split(',')])

# Development database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# CORS settings for development
CORS_ALLOW_ALL_ORIGINS = True

# Email backend for development
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}