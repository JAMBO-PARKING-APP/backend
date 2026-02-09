# Smart Parking Django System

A comprehensive parking management system built with Django, designed for municipal use with officer enforcement capabilities.

## Features

- **Phone-based Authentication** with OTP verification
- **Real-time Parking Sessions** with zone management
- **Payment Processing** with transaction tracking
- **Officer Enforcement Tools** with violation management
- **Web Dashboard** for officers and administrators
- **RESTful API** for mobile applications

## Architecture

- **Django + DRF** for backend API and web interface
- **PostgreSQL** for data storage
- **Redis** for caching and sessions
- **Celery** for background tasks
- **Bootstrap 5** for responsive web UI

## Quick Start

### 1. Environment Setup

```bash
# Clone and navigate to project
cd "PARKING SYSTEM"

# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements/development.txt
```

### 2. Database Setup

```bash
# Create PostgreSQL database
createdb smart_parking_dev

# Copy environment variables
copy .env.example .env
# Edit .env with your database credentials

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser
```

### 3. Run Development Server

```bash
python manage.py runserver
```

Visit:
- **Web Dashboard**: http://127.0.0.1:8000/
- **Admin Panel**: http://127.0.0.1:8000/admin/
- **API Root**: http://127.0.0.1:8000/api/

## API Endpoints

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/verify-otp/` - OTP verification
- `POST /api/auth/login/` - User login

### Parking
- `GET /api/parking/zones/` - List parking zones
- `POST /api/parking/sessions/start/` - Start parking session
- `POST /api/parking/sessions/end/` - End parking session

### Enforcement (Officers only)
- `GET /api/enforcement/check/{plate}/` - Check vehicle status
- `POST /api/enforcement/violations/` - Issue violation

### Payments
- `POST /api/payments/init/` - Initialize payment
- `GET /api/payments/history/` - Transaction history

## Development Workflow

### Phase 1: Core Foundation ✅
- [x] Project structure and settings
- [x] Common utilities and base models
- [x] User authentication system

### Phase 2: Core Parking Logic ✅
- [x] Zone and slot management
- [x] Parking session handling
- [x] Payment processing

### Phase 3: Enforcement System ✅
- [x] Officer tools and permissions
- [x] Violation management
- [x] Evidence handling

### Phase 4: Web Interface ✅
- [x] Bootstrap-based templates
- [x] Officer dashboard
- [x] Authentication views

## Testing

```bash
# Run tests
python manage.py test

# With coverage
coverage run --source='.' manage.py test
coverage report
```

## Production Deployment

1. **Environment**: Set `DJANGO_SETTINGS_MODULE=config.settings.production`
2. **Database**: Configure PostgreSQL with PostGIS extension
3. **Static Files**: Run `python manage.py collectstatic`
4. **Web Server**: Use Gunicorn with Nginx
5. **Background Tasks**: Start Celery workers

## Security Features

- JWT token authentication with refresh rotation
- Role-based permissions (Driver/Officer/Admin)
- CSRF protection on all forms
- Rate limiting on enforcement endpoints
- Audit logging for all officer actions

## Municipal Compliance

- **Financial Auditing**: Immutable transaction records
- **Legal Evidence**: Violation photos with GPS coordinates
- **Officer Accountability**: Complete activity logging
- **Data Integrity**: Foreign key constraints and validation

## Support

For technical issues or feature requests, please contact the development team.