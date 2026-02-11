import 'package:parking_officer_app/core/api_client.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/models/parking_session_model.dart';

class ZoneService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Zone>> getZones() async {
    try {
      final response = await _apiClient.get('officer/zones/');
      if (response.statusCode == 200) {
        return (response.data as List).map((z) => Zone.fromJson(z)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<Map<String, dynamic>> getZoneLiveStatus(String zoneId) async {
    try {
      final response = await _apiClient.get(
        'officer/zones/$zoneId/live-status/',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'zone': Zone.fromJson(data),
          'sessions': (data['active_sessions'] as List)
              .map((s) => ParkingSession.fromJson(s))
              .toList(),
        };
      }
    } catch (e) {
      return {'error': 'Failed to load live status'};
    }
    return {'error': 'Failed to load live status'};
  }

  Future<Map<String, dynamic>?> searchVehicle(String plate) async {
    try {
      final response = await _apiClient.get(
        'officer/search/vehicle/',
        queryParameters: {'plate': plate},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
