import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/parking/models/violation_model.dart';

class ViolationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Violation>> getViolations() async {
    try {
      final response = await _apiClient.get('violations/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return data.map((json) => Violation.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<Map<String, dynamic>> getViolationsSummary() async {
    try {
      final response = await _apiClient.get('violations/summary/');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      return {'unpaid_count': 0, 'total_amount': 0.0};
    }
    return {'unpaid_count': 0, 'total_amount': 0.0};
  }
}
