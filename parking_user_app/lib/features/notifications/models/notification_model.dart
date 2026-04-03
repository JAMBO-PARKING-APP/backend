class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String category;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: DateTime.parse(
        (json['created_at'] ?? json['createdAt']).toString(),
      ),
    );
  }
}

