import 'package:flutter/foundation.dart';
import 'package:parking_user_app/features/notifications/models/notification_model.dart';
import 'package:parking_user_app/features/notifications/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<NotificationModel> _notifications = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _notifications = await _service.listNotifications();
    } catch (error) {
      _errorMessage = 'Unable to load notifications: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(NotificationModel notification) async {
    await _service.setNotificationRead(notification.id, isRead: true);
    _notifications = _notifications
        .map(
          (item) => item.id == notification.id
              ? NotificationModel(
                  id: item.id,
                  title: item.title,
                  message: item.message,
                  type: item.type,
                  category: item.category,
                  isRead: true,
                  createdAt: item.createdAt,
                )
              : item,
        )
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _service.markAllAsRead();
    await fetchAll();
  }
}
