import 'package:dio/dio.dart';
import 'package:parking_officer_app/core/api_client.dart';
import 'package:parking_officer_app/features/notifications/models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> listNotifications({
    String? category,
    bool? read, // true=read, false=unread
  }) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty && category != 'all') {
      query['category'] = category;
    }
    if (read != null) {
      query['read'] = read ? 'true' : 'false';
    }

    final response = await _apiClient.get(
      'user/notifications/',
      queryParameters: query.isEmpty ? null : query,
    );

    final payload = response.data;
    final List<dynamic> data;
    if (payload is List) {
      data = payload;
    } else if (payload is Map && payload['results'] is List) {
      data = payload['results'] as List<dynamic>;
    } else {
      data = [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((n) => NotificationModel.fromJson(n))
        .toList();
  }

  Future<void> setNotificationRead(String notificationId, {required bool isRead}) async {
    await _apiClient.put(
      'user/notifications/$notificationId/',
      data: {'is_read': isRead},
    );
  }

  Future<void> markAllAsRead() async {
    await _apiClient.post(
      'user/notifications/mark-all-as-read/',
      data: {},
    );
  }

  Future<Map<String, dynamic>> summary() async {
    final response = await _apiClient.get('user/notifications/summary/');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _apiClient.get('user/preferences/');
    return response.data as Map<String, dynamic>;
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    await _apiClient.put(
      'user/preferences/',
      data: data,
    );
  }

  Future<void> registerFCMToken(String token) async {
    await _apiClient.post(
      'user/notifications/fcm/register-token/',
      data: {'token': token},
    );
  }

  Future<void> unregisterFCMToken() async {
    await _apiClient.post('user/notifications/fcm/unregister-token/', data: {});
  }
}

