import 'package:flutter/material.dart';
import 'package:parking_user_app/features/notifications/models/notification_model.dart';
import 'package:parking_user_app/features/notifications/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    final List<dynamic> data = await _notificationService.getNotifications();
    _notifications = data
        .map((json) => NotificationModel.fromJson(json))
        .toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    final success = await _notificationService.markAllAsRead();
    if (success) {
      await fetchNotifications();
    }
  }
}
