import 'package:flutter/foundation.dart';
import 'package:parking_officer_app/core/api_client.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/models/parking_session_model.dart';

class ZoneService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Zone>> getZones() async {
    try {
      // Use the user app endpoint which is available for officers too
      final response = await _apiClient.get('user/zones/');
      if (response.statusCode == 200) {
        final List data = response.data is Map
            ? response.data['results'] ?? []
            : response.data;
        return data.map((z) => Zone.fromJson(z)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  /// Get officer's assigned zones with active session counts
  Future<List<Zone>> getOfficerZones() async {
    try {
      final response = await _apiClient.get('officer/zones/');
      if (response.statusCode == 200) {
        final data = response.data;
        final List zones = data['zones'] ?? [];
        return zones.map((z) => Zone.fromJson(z)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching officer zones: $e');
      return [];
    }
    return [];
  }

  /// Get active sessions in a specific zone
  Future<Map<String, dynamic>> getZoneSessions(String zoneId) async {
    try {
      final response = await _apiClient.get('officer/zones/$zoneId/sessions/');
      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'zone': Zone.fromJson(data['zone']),
          'sessions': (data['sessions'] as List)
              .map((s) => ParkingSession.fromJson(s))
              .toList(),
          'total': data['total_sessions'] ?? 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching zone sessions: $e');
      return {'error': 'Failed to load zone sessions'};
    }
    return {'error': 'Failed to load zone sessions'};
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
