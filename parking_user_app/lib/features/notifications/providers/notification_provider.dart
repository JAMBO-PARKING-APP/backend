import 'package:flutter/material.dart';
import 'package:parking_user_app/features/notifications/models/notification_model.dart';
import 'package:parking_user_app/features/notifications/services/notification_service.dart';
import 'package:parking_user_app/core/websocket_service.dart';
import 'package:parking_user_app/core/notification_dialog_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  NotificationProvider() {
    _initWebSocketListener();
  }

  void _initWebSocketListener() {
    WebSocketService().updates.listen((update) {
      final event = update['event'];

      // If it's a notification event, check if we should show a dialog
      if (update['show_dialog'] == 'true' ||
          [
            'custom_notification',
            'campaign',
            'parking_started',
            'parking_ended',
          ].contains(event)) {
        NotificationDialogService().showNotificationDialog(update);

        // Also refresh list if a new notification was created on server
        fetchNotifications();
      }
    });
  }

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
