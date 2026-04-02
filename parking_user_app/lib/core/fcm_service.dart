import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/screens/active_session_screen.dart';
import 'api_client.dart';
import 'notification_dialog_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }

  // Initialize local notifications for background
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Process the background message
  await _processBackgroundMessage(message, flutterLocalNotificationsPlugin);
}

Future<void> _processBackgroundMessage(
  RemoteMessage message,
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
) async {
  try {
    final notification = message.notification;
    final data = message.data;

    // Show local notification for background message
    if (notification != null) {
      const androidDetails = AndroidNotificationDetails(
        'default',
        'Default Notifications',
        channelDescription: 'Default notification channel for Spave Park',
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

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(data),
      );
    }

    // Handle specific parking events in background
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'parking_ended':
          // Schedule session end notification
          if (data.containsKey('session_id')) {
            await _scheduleSessionEndNotification(data, flutterLocalNotificationsPlugin);
          }
          break;
        case 'parking_expiring':
          // Schedule expiration reminder
          if (data.containsKey('session_id')) {
            await _scheduleExpirationReminder(data, flutterLocalNotificationsPlugin);
          }
          break;
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error processing background message: $e');
    }
  }
}

Future<void> _scheduleSessionEndNotification(
  Map<String, dynamic> data,
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
) async {
  try {
    const androidDetails = AndroidNotificationDetails(
      'parking_sessions',
      'Parking Sessions',
      channelDescription: 'Notifications for parking session updates',
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

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Parking Session Ended',
      'Your parking session has ended. You have been charged accordingly.',
      details,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error scheduling session end notification: $e');
    }
  }
}

Future<void> _scheduleExpirationReminder(
  Map<String, dynamic> data,
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
) async {
  try {
    const androidDetails = AndroidNotificationDetails(
      'parking_sessions',
      'Parking Sessions',
      channelDescription: 'Notifications for parking session updates',
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

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1,
      'Parking Session Expiring Soon',
      'Your parking session will expire soon. Extend your session to avoid additional charges.',
      details,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error scheduling expiration reminder: $e');
    }
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
  bool _isUnregistering = false;

  Future<void> initialize() async {
    try {
      
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
        
        await _initializeLocalNotifications();

        
        _fcmToken = await _firebaseMessaging.getToken();
        if (kDebugMode) {
          print('FCM Token: $_fcmToken');
        }

        
        if (_fcmToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', _fcmToken!);
        }

        _setupMessageHandlers();

        
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          if (kDebugMode) {
            print('FCM Token refreshed: $newToken');
          }
          
          _registerTokenWithBackend(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing FCM: $e');
      }
    }
  }

  
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

    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'default',
        'Default Notifications',
        description: 'Default notification channel for Spave Park',
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

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.messageId}');
      }
      _showLocalNotification(message);

      NotificationDialogService().showNotificationDialog({
        'title': message.notification?.title ?? 'Notification',
        'body': message.notification?.body ?? '',
        ...message.data,
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification tapped (background): ${message.messageId}');
      }
      _handleNotificationTap(message.data);

      if (message.data['show_dialog'] == 'true') {
        NotificationDialogService().showNotificationDialog(message.data);
      }
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('Notification tapped (terminated): ${message.messageId}');
        }
        _handleNotificationTap(message.data);

        if (message.data['show_dialog'] == 'true') {
          Future.delayed(const Duration(milliseconds: 500), () {
            NotificationDialogService().showNotificationDialog(message.data);
          });
        }
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'default',
      'Default Notifications',
      channelDescription: 'Default notification channel for Spave Park',
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
      payload: jsonEncode(message.data),
    );
  }

  
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }

    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing notification payload: $e');
        }
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('Handling notification tap with data: $data');
    }

    final context = DialogService.navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'];
    switch (type) {
      case 'parking_started':
      case 'parking_expiring':
      case 'parking_ended':
        final parkingProvider = context.read<ParkingProvider>();
        parkingProvider.fetchSessions().then((_) {
          if (parkingProvider.activeSessions.isNotEmpty) {
            final session = parkingProvider.activeSessions.first;
            DialogService.navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => ActiveSessionScreen(session: session),
              ),
            );
          }
        });
        break;
      case 'payment_success':
      case 'payment_failed':
        break;
      case 'violation_issued':
        break;
      default:
        break;
    }
  }

  Future<bool> registerToken() async {
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
      final storage = StorageManager();
      final accessToken = await storage.getAccessToken();

      if (accessToken == null) {
        if (kDebugMode) {
          print(
            '[FCMService] User not authenticated, skipping backend registration',
          );
        }
        return false;
      }

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

  Future<bool> unregisterToken() async {
    if (_isUnregistering) return false;
    _isUnregistering = true;

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

      _fcmToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      return response.data['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unregistering FCM token: $e');
      }
      return false;
    } finally {
      _isUnregistering = false;
    }
  }

 
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
