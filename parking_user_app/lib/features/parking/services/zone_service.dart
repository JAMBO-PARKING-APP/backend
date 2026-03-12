import 'package:flutter/foundation.dart';
import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';

class ZoneService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Zone>> getZones() async {
    try {
      if (kDebugMode) {
        print('DEBUG: [ZoneService] Fetching zones from API...');
      }
      final response = await _apiClient.get('zones/');
      if (kDebugMode) {
        print('DEBUG: [ZoneService] API Response: ${response.statusCode}');
      }
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        if (kDebugMode) {
          print('DEBUG: [ZoneService] Zones count: ${data.length}');
        }
        return data.map((json) => Zone.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: [ZoneService] Error fetching zones: $e');
      }
      return [];
    }
    return [];
  }
}
