import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'notification_dialog_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (kDebugMode) {
        print('FCM Permission status: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Initialize local notifications for foreground messages
        await _initializeLocalNotifications();

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        if (kDebugMode) {
          print('FCM Token: $_fcmToken');
        }

        // Save token locally
        if (_fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', _fcmToken!);
        }

        // Set up message handlers
        _setupMessageHandlers();

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          if (kDebugMode) {
            print('FCM Token refreshed: $newToken');
          }
          // Register new token with backend
          _registerTokenWithBackend(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'default', // id
        'Default Notifications', // name
        description: 'Default notification channel for Space',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Set up FCM message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.messageId}');
      }
      _showLocalNotification(message);

      // Show in-app dialog if flag is set
      if (message.data['show_dialog'] == 'true') {
        NotificationDialogService().showNotificationDialog(message.data);
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification tapped (background): ${message.messageId}');
      }
      _handleNotificationTap(message.data);

      // Show in-app dialog if flag is set
      if (message.data['show_dialog'] == 'true') {
        NotificationDialogService().showNotificationDialog(message.data);
      }
    });

    // Handle notification tap when app was terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('Notification tapped (terminated): ${message.messageId}');
        }
        _handleNotificationTap(message.data);

        // Show in-app dialog if flag is set
        if (message.data['show_dialog'] == 'true') {
          // Delay to ensure UI is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            NotificationDialogService().showNotificationDialog(message.data);
          });
        }
      }
    });

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default',
      'Default Notifications',
      channelDescription: 'Default notification channel for Space',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    // Parse payload and navigate accordingly
    // This will be handled by the app's navigation logic
  }

  /// Handle notification tap with data
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('Handling notification tap with data: $data');
    }

    final type = data['type'];
    switch (type) {
      case 'parking_expiring':
      case 'parking_ended':
        // Navigate to parking sessions screen
        // This will be implemented in the app's navigation
        break;
      case 'payment_success':
      case 'payment_failed':
        // Navigate to payments screen
        break;
      case 'violation_issued':
        // Navigate to violations screen
        break;
      case 'geofence_warning':
        // Navigate to active session to show map/warning
        debugPrint('Geofence warning received');
        break;
      default:
        // Navigate to notifications screen
        break;
    }
  }

  /// Register FCM token with backend
  Future<bool> registerToken() async {
    // If token is not available, try to get it first
    if (_fcmToken == null) {
      if (kDebugMode) {
        print('FCM token not available, attempting to retrieve...');
      }

      try {
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', _fcmToken!);
          if (kDebugMode) {
            print('FCM Token retrieved: $_fcmToken');
          }
        } else {
          if (kDebugMode) {
            print('Failed to retrieve FCM token');
          }
          return false;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error retrieving FCM token: $e');
        }
        return false;
      }
    }

    return await _registerTokenWithBackend(_fcmToken!);
  }

  Future<bool> _registerTokenWithBackend(String token) async {
    try {
      if (kDebugMode) {
        print('Attempting to register FCM token with backend...');
        print('Token: ${token.substring(0, 20)}...');
      }

      final apiClient = ApiClient();
      final response = await apiClient.post(
        'notifications/fcm/register-token/',
        data: {'token': token},
      );

      if (kDebugMode) {
        print('FCM token registration response: ${response.data}');
        print('Success: ${response.data['success']}');
      }

      return response.data['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error registering FCM token with backend: $e');
      }
      return false;
    }
  }

  /// Unregister FCM token from backend (on logout)
  Future<bool> unregisterToken() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(
        'notifications/fcm/unregister-token/',
        data: {},
      );

      if (kDebugMode) {
        print(
          'FCM token unregistered from backend: ${response.data['success']}',
        );
      }

      // Clear local token
      _fcmToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      return response.data['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unregistering FCM token: $e');
      }
      return false;
    }
  }

  /// Delete FCM token (complete cleanup)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      if (kDebugMode) {
        print('FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }
}
