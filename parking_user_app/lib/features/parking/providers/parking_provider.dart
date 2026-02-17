import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';
import 'package:parking_user_app/features/parking/services/parking_service.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/core/websocket_service.dart';
import 'package:provider/provider.dart';
// Removed: flutter_overlay_window

class ParkingProvider with ChangeNotifier {
  final ParkingService _parkingService = ParkingService();
  List<ParkingSession> _sessions = [];
  List<Zone> _zones = [];
  bool _isLoading = false;
  Timer? _timer;
  // Removed overlay permissions request tracking

  List<ParkingSession> get sessions => _sessions;
  List<ParkingSession> get activeSessions =>
      _sessions.where((s) => s.status == 'active').toList();
  List<Zone> get zones => _zones;
  bool get isLoading => _isLoading;

  ParkingProvider() {
    _startTimer();
    // Initialize notifications
    initNotifications();

    // Listen to WebSocket updates
    WebSocketService().updates.listen((update) {
      if (update['type'] == 'parking_update') {
        debugPrint(
          '[ParkingProvider] Received WebSocket update: ${update['data']}',
        );
        fetchSessions();
        // Also refresh zones if occupancy changed significantly
        fetchZones();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (activeSessions.isNotEmpty) {
        final session = activeSessions.first;
        // Every 60 seconds, refresh from API as fallback (Scalability Optimization)
        if (timer.tick % 60 == 0) {
          await fetchSessions();
        }
        // Every second, update the local notifications
        await updateNotifications(session);

        // Notify UI every second for the timer countdown to look smooth
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchSessions() async {
    _isLoading = true;
    notifyListeners();
    _sessions = await _parkingService.getSessions();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchZones() async {
    _isLoading = true;
    notifyListeners();
    _zones = await _parkingService.getZones();
    _isLoading = false;
    notifyListeners();
  }

  Future<ParkingSession?> startParking({
    required BuildContext context,
    required String vehicleId,
    required String zoneId,
    double durationHours = 1.0,
    String paymentMethod = 'wallet',
  }) async {
    final session = await _parkingService.startParking(
      vehicleId: vehicleId,
      zoneId: zoneId,
      durationHours: durationHours,
      paymentMethod: paymentMethod,
    );
    if (session != null) {
      await fetchSessions();
      // Track recent zone Phase 7
      if (context.mounted) {
        await context.read<ZoneProvider>().addToRecent(zoneId);
      }
      // Refresh wallet balance in AuthProvider

      if (context.mounted) {
        await Provider.of<AuthProvider>(context, listen: false).checkAuth();
      }

      // Proactively trigger notification update
      await updateNotifications(session);
    }
    return session;
  }

  Future<bool> extendParking(String sessionId, int additionalHours) async {
    final success = await _parkingService.extendParking(
      sessionId,
      additionalHours,
    );
    if (success) await fetchSessions();
    return success;
  }

  Future<bool> endParking(String sessionId) async {
    final success = await _parkingService.endParking(sessionId);
    if (success) await fetchSessions();
    return success;
  }

  // --- Phase 6: Find My Car (Local Storage) ---

  // Actually, let's use a more robust way to handle SharedPreferences inside Provider
  Future<void> saveSpot(String sessionId, double lat, double lng) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setDouble('parked_lat_$sessionId', lat);
    await storage.setDouble('parked_lng_$sessionId', lng);
    notifyListeners();
  }

  Future<void> savePhoto(String sessionId, String path) async {
    final storage = await SharedPreferences.getInstance();
    await storage.setString('parked_photo_$sessionId', path);
    notifyListeners();
  }

  Future<Map<String, dynamic>> getSavedSpot(String sessionId) async {
    final storage = await SharedPreferences.getInstance();
    return {
      'lat': storage.getDouble('parked_lat_$sessionId'),
      'lng': storage.getDouble('parked_lng_$sessionId'),
      'photo': storage.getString('parked_photo_$sessionId'),
    };
  }

  // --- Phase 10: Out-of-app Floating Timer (Notifications) ---

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _notificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      debugPrint("[ParkingProvider] Error initializing notifications: $e");
    }
  }

  Future<void> updateNotifications(ParkingSession? session) async {
    try {
      if (session == null) {
        await _notificationsPlugin.cancel(100);
        return;
      }

      final now = DateTime.now();
      final remaining = session.endTime?.difference(now) ?? Duration.zero;

      if (remaining.isNegative || remaining.inSeconds == 0) {
        // Session Expired!
        await _notificationsPlugin.show(
          100,
          'Parking Session Ended',
          'Please vacate the premises immediately.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'parking_timer',
              'Parking Timer',
              importance: Importance.max,
              priority: Priority.high,
              ongoing: false,
            ),
          ),
        );
        // Automatically end session on server if it's still active in our local state
        // This is a safety catch
        if (session.status == 'active') {
          await endParking(session.id);
        }
        return;
      }

      final String timeStr = _formatDuration(remaining);

      // Update Notification
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'parking_timer',
            'Parking Timer',
            channelDescription: 'Active parking session timer',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            onlyAlertOnce: true,
            showWhen: false,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      // Only update notification every 10 seconds to reduce engine load
      if (now.second % 10 == 0) {
        await _notificationsPlugin.show(
          100,
          'Active Parking: ${session.zoneName}',
          'Time remaining: $timeStr',
          platformChannelSpecifics,
        );
      }
    } catch (e) {
      debugPrint("[ParkingProvider] Error in updateNotifications: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Removed floating timer toggle code
}

// Global explorer key might be needed for context-less calls if any
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
