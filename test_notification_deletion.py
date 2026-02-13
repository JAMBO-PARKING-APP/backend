import os
import django
from rest_framework.test import APIRequestFactory, force_authenticate

# Setup Django
import sys
project_root = 'C:\\Users\\tutum\\Downloads\\JAMBO PARK'
if project_root not in sys.path:
    sys.path.append(project_root)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')
import django
django.setup()

from apps.notifications.models import NotificationEvent
from apps.notifications.api_views import NotificationDetailAPIView, MarkAllNotificationsAsReadAPIView
from apps.accounts.models import User

def test_deletion():
    user = User.objects.first()
    if not user:
        print("No user found")
        return
    
    print(f"Testing for user: {user.phone}")
    
    # 1. Clear existing unread
    NotificationEvent.objects.filter(user=user, is_read=False).delete()
    
    # 2. Create test notifications
    n1 = NotificationEvent.objects.create(user=user, title="Test 1", message="Msg 1")
    n2 = NotificationEvent.objects.create(user=user, title="Test 2", message="Msg 2")
    n3 = NotificationEvent.objects.create(user=user, title="Test 3", message="Msg 3")
    
    factory = APIRequestFactory()
    
    # 3. Test individual deletion
    print(f"Total before individual: {NotificationEvent.objects.filter(user=user).count()}")
    request = factory.put(f'/api/notifications/{n1.id}/', {'is_read': True}, format='json')
    force_authenticate(request, user=user)
    view = NotificationDetailAPIView.as_view()
    response = view(request, pk=n1.id)
    print(f"Individual Delete Response: {response.status_code}")
    print(f"Total after individual: {NotificationEvent.objects.filter(user=user).count()}")
    
    # 4. Test bulk deletion
    request = factory.post('/api/notifications/mark-all-as-read/')
    force_authenticate(request, user=user)
    view = MarkAllNotificationsAsReadAPIView.as_view()
    response = view(request)
    print(f"Bulk Delete Response: {response.status_code} - {response.data}")
    print(f"Total after bulk: {NotificationEvent.objects.filter(user=user).count()}")

if __name__ == "__main__":
    test_deletion()
