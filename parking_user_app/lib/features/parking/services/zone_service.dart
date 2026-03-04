import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';

class ZoneService {
  final ApiClient _apiClient = ApiClient();

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
      // print('DEBUG: getZones error: $e');
      return [];
    }
    return [];
  }
}
