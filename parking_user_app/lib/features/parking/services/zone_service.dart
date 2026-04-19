import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';

class ZoneService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Zone>> getZones() async {
    try {
      final response = await _apiClient.get('user/zones/');
      if (response.statusCode == 200) {
        final dynamic payload = response.data;
        final List<dynamic> data;
        if (payload is List) {
          data = payload;
        } else if (payload is Map && payload['results'] is List) {
          data = payload['results'] as List<dynamic>;
        } else {
          data = [];
        }

        return data.map((z) => Zone.fromJson(z as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<Zone?> getZoneDetail(String zoneId) async {
    try {
      final response = await _apiClient.get('user/zones/$zoneId/');
      if (response.statusCode == 200 && response.data is Map) {
        return Zone.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
