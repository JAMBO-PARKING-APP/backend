import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/main.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_officer_app/features/auth/providers/vehicle_provider.dart';
import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      await _firebaseMessaging.setAutoInitEnabled(true);
      await Firebase.initializeApp();

      await _initializeLocalNotifications();

      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User app: User granted notification permission');

        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('User FCM Token: $_fcmToken');

        if (_fcmToken != null) await _registerTokenWithBackend(_fcmToken!);

        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _registerTokenWithBackend(newToken);
        });

        _setupMessageHandlers();

        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      } else {
        debugPrint('User app: User declined notification permission');
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Call after login to ensure token is registered with auth context.
  Future<void> syncTokenWithBackend() async {
    try {
      _fcmToken ??= await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _registerTokenWithBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

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

    const androidChannel = AndroidNotificationChannel(
      'space_user_channel',
      'SPACE Notifications',
      description: 'Notifications for SPACE users',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
      _showLocalNotification(message);

      final type = message.data['type'];
      if (type == 'session_ended' ||
          type == 'session_extended' ||
          type == 'violation_reported') {
        _refreshAppData(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened: ${message.notification?.title}');
      _handleNotificationTap(message.data);
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          'App opened from notification: ${message.notification?.title}',
        );
        _handleNotificationTap(message.data);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'space_user_channel',
            'SPACE Notifications',
            channelDescription: 'Notifications for SPACE users',
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

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    debugPrint('Handling notification tap: $type');

    switch (type) {
      case 'chat_message':
        debugPrint('Navigate to chat: ${data['conversation_id']}');
        break;
      case 'session_ended':
        debugPrint('Navigate to session: ${data['session_id']}');
        break;
      case 'violation_reported':
        debugPrint('Navigate to violations');
        break;
      case 'officer_dispatch':
        debugPrint('Navigate to zone: ${data['zone_id']} for hotspot dispatch');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final apiClient = ApiClient();
      await apiClient.post(
        'user/notifications/fcm/register-token/',
        data: {'token': token},
      );
      debugPrint('User FCM token registered with backend');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  Future<void> unregisterToken() async {
    try {
      final apiClient = ApiClient();
      await apiClient.post(
        'user/notifications/fcm/unregister-token/',
        data: {'token': _fcmToken},
      );
      debugPrint('User FCM token unregistered');
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
    }
  }

  void _refreshAppData(RemoteMessage message) {
    final context = SpaceUserApp.navigatorKey.currentContext;
    if (context != null) {
      debugPrint('Refreshing app data from FCM trigger');
      context.read<ZoneProvider>().fetchZones();
      // Keep user data in sync with backend.
      context.read<ReservationProvider>().fetchReservations();
      context.read<VehicleProvider>().fetchVehicles();

      // Show immediate feedback for foreground users
      final notification = message.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title ?? 'System Update',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        notification.body ?? 'Data has been refreshed.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
