import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';

class ZoneService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Zone>> getZones() async {
    final response = await _apiClient.get('user/zones/');
    final dynamic payload = response.data;
    final List<dynamic> data;
    if (payload is List) {
      data = payload;
    } else if (payload is Map && payload['results'] is List) {
      data = payload['results'] as List<dynamic>;
    } else {
      throw const FormatException('The zones response was not a list.');
    }
    return data
        .whereType<Map>()
        .map((zone) => Zone.fromJson(zone.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Zone?> getZoneDetail(String zoneId) async {
    final response = await _apiClient.get('user/zones/$zoneId/');
    if (response.data is! Map) {
      throw const FormatException('The zone detail response was invalid.');
    }
    return Zone.fromJson((response.data as Map).cast<String, dynamic>());
  }
}
