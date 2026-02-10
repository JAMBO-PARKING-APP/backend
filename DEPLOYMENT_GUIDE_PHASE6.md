# Jambo Park - Phase 6 Deployment Guide

## 🚀 Pre-Deployment Checklist

### Backend Requirements
- [ ] PostgreSQL database running
- [ ] Redis server running (for caching)
- [ ] Python 3.10+ with Django 4.2
- [ ] All requirements.txt packages installed

### Flutter Requirements
- [ ] Flutter SDK 3.10+
- [ ] Android SDK 21+ (or iOS 12+)
- [ ] All pubspec.yaml dependencies available

---

## 📋 Step-by-Step Deployment

### Phase 1: Database Migrations (Backend)

```bash
# Navigate to project root
cd "C:\Users\tutum\Downloads\JAMBO PARK"

# Create migrations for new indexes
python manage.py makemigrations accounts
python manage.py makemigrations parking
python manage.py makemigrations payments
python manage.py makemigrations notifications

# Apply all migrations
python manage.py migrate

# Verify database changes
python manage.py showmigrations
```

**Expected Output**:
```
[X] accounts.0004_add_indexes
[X] parking.0003_add_indexes  
[X] payments.0002_add_indexes
[X] notifications.0002_chat_models
```

---

### Phase 2: Setup i18n Translations (Backend)

```bash
# Create translation files for Swahili, French, Spanish
python manage.py makemessages -l sw -l fr -l es

# Now edit the .po files in locale/sw/LC_MESSAGES/django.po, etc.
# Find "msgstr" entries and add translations
# Example:
#     msgid "Parking"
#     msgstr "Kukamatia"  (in Swahili)

# Compile translations to binary format
python manage.py compilemessages

# Verify translations compiled
ls locale/*/LC_MESSAGES/django.mo
```

---

### Phase 3: Configure Caching (Backend)

```bash
# Ensure Redis is running
redis-cli ping  # Should return "PONG"

# Test Django cache
python manage.py shell
>>> from django.core.cache import cache
>>> cache.set('test', 'hello', 60)
>>> print(cache.get('test'))  # Should print "hello"
>>> exit()
```

**Docker Option** (if Redis not installed):
```bash
# Pull and run Redis
docker run -d -p 6379:6379 redis:7

# Test connection
redis-cli -h localhost -p 6379 ping
```

---

### Phase 4: Test Backend Locally

```bash
# Start development server
python manage.py runserver 0.0.0.0:8000

# In another terminal, test API endpoints
curl http://localhost:8000/api/user/chat/conversations/

# Example response:
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": []
}
```

---

### Phase 5: Flutter Setup

```bash
# Navigate to Flutter app
cd parking_user_app

# Get all dependencies (including intl for localization)
flutter pub get

# Build for Android (example)
flutter build apk --release

# Or build for iOS
flutter build ios --release
```

#### Verify Localization:
```bash
# Check that localization is compiled in Flutter
flutter pub get
flutter run  # Should load in English

# In app settings, verify language switching works
```

---

### Phase 6: Testing Chat Functionality

**Test 1: Create Conversation**
```bash
# Using curl or Postman
POST http://localhost:8000/api/user/chat/conversations/
Headers: { "Authorization": "Bearer YOUR_TOKEN" }
Body: {
  "subject": "Issue with parking payment",
  "category": "payment",
  "priority": "high"
}

# Response: 201 Created with conversation ID
```

**Test 2: Send Message**
```bash
POST http://localhost:8000/api/user/chat/conversations/1/send_message/
Headers: { "Authorization": "Bearer YOUR_TOKEN" }
Body: {
  "content": "I didn't receive a receipt",
  "message_type": "text"
}
```

**Test 3: Get Messages**
```bash
GET http://localhost:8000/api/user/chat/conversations/1/messages/
```

**Test 4: Create Multiple Languages**
```bash
# In Flutter app, go to Settings
# Toggle language: English → Swahili → French
# Verify all strings translate correctly
```

---

### Phase 7: Production Deployment

#### Backend (Production)
```bash
# 1. Update Django settings
# Set DEBUG = False in config/settings/production.py
# Ensure ALLOWED_HOSTS includes your domain

# 2. Collect static files
python manage.py collectstatic --noinput

# 3. Run migrations on production database
python manage.py migrate --database=production

# 4. Setup production server (nginx + gunicorn)
gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 4

# 5. Setup Redis (managed service or dedicated instance)
# Redis should be accessible at your REDIS_URL env var
```

#### Flutter (Production)
```bash
# Build release APK for Android
flutter build apk --release

# Build release IPA for iOS
flutter build ios --release

# Upload to Google Play / App Store
```

#### Environment Variables
Create `.env` file with:
```
SECRET_KEY=your-secret-key
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,api.yourdomain.com
DB_NAME=jambo_park_prod
DB_USER=postgres
DB_PASSWORD=strong-password
DB_HOST=your-db-server.com
DB_PORT=5432
REDIS_URL=redis://your-redis-server.com:6379/0
PESAPAL_CONSUMER_KEY=your-key
PESAPAL_CONSUMER_SECRET=your-secret
TWILIO_ACCOUNT_SID=your-sid
TWILIO_AUTH_TOKEN=your-token
TWILIO_VERIFY_SERVICE_ID=your-service-id
```

---

## ✅ Verification Checklist

### Database Indexes
```bash
# Check indexes were created
python manage.py shell
>>> from django.db import connection
>>> cursor = connection.cursor()
>>> cursor.execute("""
...   SELECT indexname FROM pg_indexes 
...   WHERE tablename = 'accounts_user' OR tablename = 'parking_parkingsession'
... """)
>>> for idx in cursor.fetchall(): print(idx[0])
# Should show: accounts_user_is_active_idx, parking_session_vehicle_status_idx, etc.
```

### Caching
```bash
# Monitor cache hits/misses
from django.core.cache import cache
print(cache.get('zones_list'))  # Should be populated after first request
```

### Chat Models
```bash
# Verify chat tables exist
python manage.py dbshell
\dt notifications_chat*
# Should show: notifications_chatconversation, notifications_chatmessage
```

### i18n Setup
```bash
# Test Django translation
python manage.py shell
>>> from django.utils.translation import gettext as _
>>> from django.conf import settings
>>> settings.LANGUAGE_CODE = 'sw'
>>> _('Parking')  # Should work if translations compiled
```

---

## 🐛 Troubleshooting

### Issue: Cache not working
**Solution**:
```bash
# Check Redis connection
redis-cli ping  # Should return PONG

# If not working, restart Redis
docker restart <container_id>

# Clear cache
python manage.py shell
>>> from django.core.cache import cache
>>> cache.clear()
```

### Issue: Chat migrations fail
**Solution**:
```bash
# Check migration dependencies
python manage.py showmigrations notifications

# If conflict, rollback and reapply
python manage.py migrate notifications zero  # Rollback all
python manage.py migrate notifications  # Reapply
```

### Issue: Localization strings not translating
**Solution**:
```bash
# Recompile translations
python manage.py compilemessages -v2

# Check .po file syntax
msgfmt --check locale/sw/LC_MESSAGES/django.po

# If error, fix and recompile
```

### Issue: Flutter app crashes on chat
**Solution**:
```bash
# Check logs
flutter run -v

# Verify URL configuration
# In lib/core/constants.dart, ensure baseUrl is correct

# Test API endpoint directly
curl -H "Authorization: Bearer TOKEN" http://your-api/api/user/chat/conversations/
```

---

## 📊 Performance Monitoring

### Monitor Query Performance
```bash
# Enable PostgreSQL logging
ALTER DATABASE jambo_park SET log_statement = 'all';
ALTER DATABASE jambo_park SET log_min_duration_statement = 100;  # Log queries > 100ms

# Check slow queries
tail -f /var/log/postgresql/postgresql.log | grep "duration:"
```

### Monitor Cache Hit Rate
```python
# Add to Django management command
from django.core.cache import cache
stats = cache.get_stats()
print(f"Cache hits: {stats['hits']}")
print(f"Cache misses: {stats['misses']}")
print(f"Hit rate: {stats['hits'] / (stats['hits'] + stats['misses']) * 100}%")
```

### Monitor API Response Times
```bash
# Using curl with timing
curl -w '@curl-format.txt' -o /dev/null -s http://your-api/api/user/chat/conversations/

# curl-format.txt contents:
# time_connect:  %{time_connect}
# time_starttransfer: %{time_starttransfer}
# time_total: %{time_total}
```

---

## 🔄 Rollback Procedure

If something breaks in production:

```bash
# 1. Rollback database to previous version
python manage.py migrate notifications 0001_initial
python manage.py migrate accounts 0003_user
python manage.py migrate parking 0002_*
python manage.py migrate payments 0001_*

# 2. Clear cache
python manage.py shell
>>> from django.core.cache import cache
>>> cache.clear()

# 3. Restart application server
sudo systemctl restart gunicorn

# 4. Investigate issue before redeploying
```

---

## 📞 Support & Escalation

**For Database Issues**:
- Check PostgreSQL logs: `sudo tail -f /var/log/postgresql/postgresql.log`
- Monitor connections: `SELECT count(*) FROM pg_stat_activity;`

**For Redis Issues**:
- Check Redis memory: `redis-cli info memory`
- Clear expired keys: `redis-cli FLUSHDB`

**For Flutter Issues**:
- Check deviceemulator logs: `flutter logs`
- Clear app cache: `flutter clean && flutter pub get`

---

## ✨ Post-Deployment (Day 1)

- [ ] Monitor error logs for any exceptions
- [ ] Check API response time metrics
- [ ] Verify all chat conversations save correctly
- [ ] Test language switching with multiple users
- [ ] Monitor database performance
- [ ] Verify cache is reducing API load

---

**Estimated Deployment Time**: 2-3 hours  
**Rollback Time**: 15 minutes  
**Expected Downtime**: 5 minutes (during migration)

**Last Updated**: February 10, 2026
