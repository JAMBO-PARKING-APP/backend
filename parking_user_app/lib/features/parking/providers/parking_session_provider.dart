import 'package:flutter/foundation.dart';
import 'package:parking_user_app/core/analytics_service.dart';
import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';

class ParkingSessionProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<ParkingSession> _sessions = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ParkingSession> get sessions => _sessions;
  List<ParkingSession> get activeSessions =>
      _sessions.where((session) => session.status == 'active').toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.get('user/parking/sessions/');
      final dynamic payload = response.data;
      final List<dynamic> items;
      if (payload is List) {
        items = payload;
      } else if (payload is Map && payload['results'] is List) {
        items = payload['results'] as List<dynamic>;
      } else if (payload is Map && payload['sessions'] is List) {
        items = payload['sessions'] as List<dynamic>;
      } else {
        throw const FormatException(
          'The parking session response was invalid.',
        );
      }
      _sessions = items
          .whereType<Map>()
          .map((item) => ParkingSession.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (error) {
      _errorMessage = 'Unable to load parking sessions: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startSession({
    required String vehicleId,
    required String zoneId,
    required int durationMinutes,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _api.post(
        'user/parking/start/',
        data: {
          'vehicle_id': vehicleId,
          'zone_id': zoneId,
          'duration_hours': durationMinutes / 60,
          'payment_method': 'wallet',
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      await fetchSessions();
      AnalyticsService.logEvent(
        name: 'parking_started',
        parameters: {
          'duration_minutes': durationMinutes,
          'payment_method': 'wallet',
          'success': true,
        },
      );
      return true;
    } catch (error) {
      AnalyticsService.logEvent(
        name: 'parking_started',
        parameters: {
          'duration_minutes': durationMinutes,
          'payment_method': 'wallet',
          'success': false,
        },
      );
      _errorMessage = 'Unable to start parking: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> endSession(String sessionId) async {
    try {
      await _api.post('user/parking/end/', data: {'session_id': sessionId});
      await fetchSessions();
      AnalyticsService.logEvent(
        name: 'parking_ended',
        parameters: const {'success': true},
      );
      return true;
    } catch (error) {
      AnalyticsService.logEvent(
        name: 'parking_ended',
        parameters: const {'success': false},
      );
      _errorMessage = 'Unable to end parking: $error';
      notifyListeners();
      return false;
    }
  }
}
