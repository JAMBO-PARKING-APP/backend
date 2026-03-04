class ChatConversation {
  final String id;
  final String userId;
  final String userName;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final String status;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    this.lastMessage,
    required this.lastMessageTime,
    required this.status,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_full_name'] ?? 'User',
      lastMessage: json['last_message'],
      lastMessageTime: DateTime.parse(json['updated_at'] ?? json['created_at']),
      status: json['status'] ?? 'open',
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String messageType;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.messageType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['created_at']),
      messageType: json['message_type'] ?? 'text',
    );
  }
}
