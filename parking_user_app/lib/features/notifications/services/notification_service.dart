import 'package:parking_user_app/core/api_client.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _apiClient.get('notifications/');
      if (response.statusCode == 200) {
        return response.data is List
            ? response.data
            : (response.data['results'] ?? []);
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.post('notifications/mark-all-as-read/');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
