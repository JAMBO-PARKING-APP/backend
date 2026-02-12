import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

/// FCM Service for Officer App
/// Handles push notifications for chat messages and session events
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM
  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Officer app: User granted notification permission');

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        print('Officer FCM Token: $_fcmToken');

        // Register token with backend
        if (_fcmToken != null) {
          await _registerTokenWithBackend(_fcmToken!);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _registerTokenWithBackend(newToken);
        });

        // Set up message handlers
        _setupMessageHandlers();

        // Set background message handler
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      } else {
        print('Officer app: User declined notification permission');
      }
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
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
    const androidChannel = AndroidNotificationChannel(
      'jambo_officer_channel',
      'Jambo Officer Notifications',
      description: 'Notifications for parking officers',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Message opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened: ${message.notification?.title}');
      _handleNotificationTap(message.data);
    });

    // Check for initial message (app opened from terminated state)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from notification: ${message.notification?.title}');
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'jambo_officer_channel',
            'Jambo Officer Notifications',
            channelDescription: 'Notifications for parking officers',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on notification type
  }

  /// Handle notification tap with data
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    print('Handling notification tap: $type');

    // TODO: Implement navigation based on notification type
    switch (type) {
      case 'chat_message':
        // Navigate to chat screen
        print('Navigate to chat: ${data['conversation_id']}');
        break;
      case 'session_ended':
        // Navigate to session details
        print('Navigate to session: ${data['session_id']}');
        break;
      case 'violation_reported':
        // Navigate to violations
        print('Navigate to violations');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final apiClient = ApiClient();
      await apiClient.post(
        '/api/notifications/fcm/register-token/',
        data: {'fcm_token': token},
      );
      print('Officer FCM token registered with backend');
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }

  /// Unregister FCM token
  Future<void> unregisterToken() async {
    try {
      final apiClient = ApiClient();
      await apiClient.post('/api/notifications/fcm/unregister-token/');
      print('Officer FCM token unregistered');
    } catch (e) {
      print('Error unregistering FCM token: $e');
    }
  }
}
