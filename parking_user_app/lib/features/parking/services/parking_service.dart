import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';

class ParkingService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ParkingSession>> getSessions() async {
    try {
      final response = await _apiClient.get('parking/sessions/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return data.map((json) => ParkingSession.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<List<Zone>> getZones() async {
    try {
      final response = await _apiClient.get('zones/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return data.map((json) => Zone.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<ParkingSession?> startParking({
    required String zoneId,
    required String vehicleId,
    double durationHours = 1.0,
    String paymentMethod = 'wallet',
  }) async {
    try {
      final response = await _apiClient.post(
        'parking/start/',
        data: {
          'zone_id': zoneId,
          'vehicle_id': vehicleId,
          'duration_hours': durationHours,
          'payment_method': paymentMethod,
        },
      );
      if (response.statusCode == 201 && response.data['session'] != null) {
        return ParkingSession.fromJson(response.data['session']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> endParking(String sessionId) async {
    try {
      final response = await _apiClient.post(
        'parking/end/',
        data: {'session_id': sessionId},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> extendParking(String sessionId, int additionalHours) async {
    try {
      final response = await _apiClient.post(
        'parking/extend/',
        data: {'session_id': sessionId, 'additional_hours': additionalHours},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
