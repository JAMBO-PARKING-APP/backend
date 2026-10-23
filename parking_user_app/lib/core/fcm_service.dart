import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:parking_user_app/core/api_client.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // StartupPermissionService owns the user-facing permission prompt.
    // Initialize notification delivery here without prompting a second time.
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Handle token registration
    await syncTokenWithBackend();

    // Set up message listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[FCM] Received foreground message: ${message.notification?.title}',
      );
      _showLocalNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  }

  // Alias for compatibility
  Future<void> registerToken() => syncTokenWithBackend();

  Future<void> syncTokenWithBackend() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('[FCM] Registration Token: $token');

        // Use dedicated FCM registration endpoint
        await _apiClient.post(
          'user/notifications/fcm/register-token/',
          data: {'token': token},
        );
        debugPrint('[FCM] Token registered successfully with backend');
      }
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'parking_alerts',
          'Parking Alerts',
          channelDescription: 'Real-time parking notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      message.notification?.title ?? 'Parking Alert',
      message.notification?.body ?? '',
      details,
    );
  }
}

// Global background handler required by Firebase
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Received background message: ${message.messageId}');
}
