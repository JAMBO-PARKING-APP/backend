from django.contrib import admin
from .models import NotificationEvent, ChatConversation, ChatMessage

@admin.register(NotificationEvent)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'title', 'type', 'is_read', 'created_at')
    list_filter = ('type', 'category', 'is_read', 'created_at')
    search_fields = ('user__phone', 'user__first_name', 'user__last_name', 'title', 'message')
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        (None, {'fields': ('user', 'title', 'message')}),
        ('Details', {'fields': ('type', 'category', 'is_read', 'metadata')}),
        ('Timestamps', {'fields': ('created_at', 'updated_at')}),
    )
    
    actions = ['mark_as_read', 'mark_as_unread']
    
    def mark_as_read(self, request, queryset):
        count = queryset.update(is_read=True)
        self.message_user(request, f'{count} notification(s) marked as read')
    mark_as_read.short_description = 'Mark selected as read'
    
    def mark_as_unread(self, request, queryset):
        count = queryset.update(is_read=False)
        self.message_user(request, f'{count} notification(s) marked as unread')
    mark_as_unread.short_description = 'Mark selected as unread'


@admin.register(ChatConversation)
class ChatConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'assigned_agent', 'status', 'priority', 'created_at')
    list_filter = ('status', 'priority', 'category', 'created_at')
    search_fields = ('user__phone', 'user__first_name', 'subject', 'assigned_agent__username')
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        ('User Info', {'fields': ('user', 'subject')}),
        ('Assignment', {'fields': ('assigned_agent', 'status')}),
        ('Details', {'fields': ('priority', 'category', 'resolved_at')}),
        ('Timestamps', {'fields': ('created_at', 'updated_at')}),
    )
    
    actions = ['mark_as_open', 'mark_as_in_progress', 'mark_as_resolved']
    
    def mark_as_open(self, request, queryset):
        count = queryset.update(status='open')
        self.message_user(request, f'{count} conversation(s) marked as open')
    mark_as_open.short_description = 'Mark as Open'
    
    def mark_as_in_progress(self, request, queryset):
        count = queryset.update(status='in_progress')
        self.message_user(request, f'{count} conversation(s) marked as in progress')
    mark_as_in_progress.short_description = 'Mark as In Progress'
    
    def mark_as_resolved(self, request, queryset):
        from django.utils import timezone
        count = queryset.update(status='resolved', resolved_at=timezone.now())
        self.message_user(request, f'{count} conversation(s) marked as resolved')
    mark_as_resolved.short_description = 'Mark as Resolved'


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'conversation', 'sender_name', 'message_type', 'is_read', 'created_at')
    list_filter = ('message_type', 'is_read', 'created_at')
    search_fields = ('conversation__subject', 'sender__phone', 'content')
    readonly_fields = ('created_at', 'read_at')
    ordering = ('-created_at',)
    
    fieldsets = (
        ('Conversation', {'fields': ('conversation',)}),
        ('Sender', {'fields': ('sender',)}),
        ('Message', {'fields': ('message_type', 'content', 'attachment')}),
        ('Status', {'fields': ('is_read', 'read_at')}),
        ('Timestamps', {'fields': ('created_at',)}),
    )
    
    actions = ['mark_as_read']
    
    def sender_name(self, obj):
        if obj.sender:
            return f"{obj.sender.get_role_display()}: {obj.sender.full_name or obj.sender.phone}"
        return "Unknown"
    sender_name.short_description = 'Sender'
    
    def mark_as_read(self, request, queryset):
        from django.utils import timezone
        count = queryset.update(is_read=True, read_at=timezone.now())
        self.message_user(request, f'{count} message(s) marked as read')
    mark_as_read.short_description = 'Mark as Read'
