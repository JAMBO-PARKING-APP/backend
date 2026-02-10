# Django Admin - Live Chat Management Guide

## Access Django Admin

1. **Start Django server**:
   ```bash
   python manage.py runserver
   ```

2. **Open in browser**:
   ```
   http://127.0.0.1:8000/admin
   ```

3. **Login with superuser credentials**:
   ```bash
   # If you don't have a superuser, create one:
   python manage.py createsuperuser
   # Follow prompts for username, email, password
   ```

## Chat Conversations Management

### Location
Dashboard → Notifications → Chat Conversations

### View All Conversations

**Features**:
- Filter by: Status (open, in_progress, resolved), Priority, Category, Date
- Search by: User phone, User name, Subject
- Bulk actions: Mark as opened, in progress, or resolved
- Readonly fields: Created at, Updated at

### Create New Conversation (for testing)

**Fields**:
- **User**: Select user (phone number shown)
- **Subject**: Conversation title (required)
- **Assigned Agent**: Support staff to assign (optional)
- **Status**: open | in_progress | resolved (defaults: open)
- **Priority**: low | medium | high | urgent
- **Category**: 
  - parking
  - payment
  - violation
  - subscription
  - account
  - technical
  - other
- **Resolved At**: Auto-filled when marked as resolved

### Bulk Actions

**Mark as Open**:
- Select conversations → Action dropdown → Mark as Open → Go

**Mark as In Progress**:
- Assign agent first
- Select conversations → Action dropdown → Mark as In Progress → Go

**Mark as Resolved**:
- Select conversations → Action dropdown → Mark as Resolved → Go
- Auto-fills resolved_at timestamp

## Chat Messages Management

### Location
Dashboard → Notifications → Chat Messages

### View All Messages

**Features**:
- Filter by: Message type, Read status, Date
- Search by: Conversation, Sender, Content
- Readonly fields: Created at, Read at

### Message Types
- **text**: Regular text messages
- **system**: Automated system messages (e.g., "Conversation closed")
- **agent_note**: Internal notes (not visible to user)

### Sender Information

**Sender Type**:
- **user**: Customer message
- **agent**: Support staff response

**Sender ID**: User ID or Agent ID

### Mark as Read

- Select messages → Action dropdown → Mark as Read → Go
- Updates read_at timestamp automatically

### Monitor Response Times

Check message timestamps to ensure:
- Users get responses within reasonable time
- Agents are actively managing conversations

## Real-Time Chat Monitoring

### Check Live Conversations

1. Go to Chat Conversations
2. Filter by Status = "open"
3. View unread message counts
4. Click conversation to view all messages

### User Activity

- New conversations appear immediately (if you refresh)
- Messages poll every 3 seconds (app-side)
- Status changes reflect in real-time

## Testing Live Chat Features in Admin

### Test Scenario 1: Create & Send Message

1. **Create conversation**:
   - Go to Chat Conversations → Add
   - Set Subject, Category, Priority
   - Click Save

2. **Send message from app**:
   - User starts app
   - Chat icon → Create Conversation (use same subject)
   - Send a test message

3. **View in admin**:
   - Refresh Chat Messages
   - See user's message appear
   - Compose response in reverse chat if possible

### Test Scenario 2: Agent Response

1. **In admin**, go to Chat Messages
2. Manually add a message:
   - Select conversation
   - Click "Add Chat Message"
   - Set:
     - Conversation: [select user's conversation]
     - Sender ID: [your user ID or agent ID]
     - Sender Type: "agent"
     - Message Type: "text"
     - Content: "Thank you for contacting support!"
   - Click Save

3. **In app**:
   - Go to that conversation
   - New message appears within 3 seconds (polling)

### Test Scenario 3: Close Conversation

1. **In admin**:
   - Select conversation
   - Action → Mark as Resolved
   - Click Go

2. **In app**:
   - Conversation status changes to "resolved"
   - User can still view message history
   - Cannot send new messages

## Performance Monitoring

### Check Database Performance

```bash
# View database indexes created:
python manage.py dbshell

# Then run:
SELECT tablename, indexname FROM pg_indexes 
WHERE schemaname = 'public' AND tablename IN ('chatconversation', 'chatmessage');

# Expected: 4 indexes total
# - chatconversation user_id + status
# - chatconversation status + created_at
# - chatmessage conversation_id + created_at
# - chatmessage is_read + sender_id
```

### Monitor Active Sessions

- Chat Conversations count should increase as users send messages
- Chat Messages count should increase with activity
- Resolved conversations: Archive old ones for better DB performance

## Common Admin Tasks

### Finding a User's Conversations

1. **Search by user**:
   - Go to Chat Conversations
   - Search box (top right)
   - Enter user's phone number
   - View all their conversations

### Assigning Agent to Conversation

1. Click conversation to edit
2. "Assigned Agent" dropdown → Select agent username
3. Save
4. Conversation status automatically changes to "in_progress"

### Closing Old Conversations

1. Filter by Status = "open"
2. Filter by Created At = "[older than 30 days]"
3. Select all (checkbox in header)
4. Action → Mark as Resolved
5. Go

### Bulk Export Messages

1. Go to Chat Messages
2. Select messages (or all)
3. Use Django admin export feature (if configured)

## Integration with Notifications

Chat conversations automatically create **NotificationEvent** entries:
- User receives notification when agent responds
- User receives notification when conversation is closed
- View in: Notifications → Notification Events

## Analytics

### Track Chat Metrics

```bash
# Via Django shell:
python manage.py shell

# View conversations by status:
from apps.notifications.models import ChatConversation
ChatConversation.objects.all().values('status').annotate(count=Count('id'))

# View average response time:
from django.db.models import F, DurationField
from django.db.models.functions import Extract
ChatMessage.objects.filter(sender_type='agent').annotate(
    response_time=F('created_at') - F('conversation__created_at')
)

# View most common issues:
ChatConversation.objects.all().values('category').annotate(count=Count('id')).order_by('-count')
```

## Troubleshooting Admin Issues

### Cannot see Chat Conversations option

**Solution**: Ensure notifications app is in INSTALLED_APPS

```python
# config/settings/base.py
LOCAL_APPS = [
    ...
    'apps.notifications',  # Must be here
    ...
]
```

### Dates showing incorrectly

**Solution**: Check Django TIME_ZONE setting

```python
# config/settings/base.py
TIME_ZONE = 'Africa/Nairobi'  # Adjust to your timezone
USE_TZ = True
```

### Cannot filter conversations

**Solution**: Run migrations

```bash
python manage.py migrate
```

### Too many conversations, admin page slow

**Solution**: Add pagination

```python
# apps/notifications/admin.py
list_per_page = 50  # Reduce from default 100
```

## Next Steps

1. Create test users via admin
2. Send test chat messages from Flutter app
3. Monitor admin for real-time updates
4. Test agent responses
5. Monitor performance metrics
6. Set up daily backups
7. Archive resolved conversations monthly

## Support

For admin-specific issues:
- Check Django documentation: https://docs.djangoproject.com/admin/
- Check Django REST Framework: https://www.django-rest-framework.org/
- Contact development team for custom admin features
