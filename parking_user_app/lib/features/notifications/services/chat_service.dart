import 'package:dio/dio.dart';
import '../../../core/constants.dart';

class ChatService {
  final Dio _dio;

  ChatService({Dio? dio}) : _dio = dio ?? Dio();

  /// Get all chat conversations for the user
  Future<Map<String, dynamic>> getConversations({
    int page = 1,
    String? status,
  }) async {
    try {
      String url = '${AppConstants.baseUrl}chat/conversations/';
      Map<String, dynamic> queryParams = {'page': page};

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fetch conversations'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Create a new support conversation
  Future<Map<String, dynamic>> createConversation({
    required String subject,
    required String category,
    String priority = 'medium',
  }) async {
    try {
      String url = '${AppConstants.baseUrl}chat/conversations/';

      final response = await _dio.post(
        url,
        data: {'subject': subject, 'category': category, 'priority': priority},
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to create conversation'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get messages in a conversation
  Future<Map<String, dynamic>> getMessages({
    required int conversationId,
    int page = 1,
  }) async {
    try {
      String url =
          '${AppConstants.baseUrl}chat/conversations/$conversationId/messages/';

      final response = await _dio.get(
        url,
        queryParameters: {'page': page},
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fetch messages'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Send a message in a conversation
  Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      String url =
          '${AppConstants.baseUrl}chat/conversations/$conversationId/send_message/';

      final response = await _dio.post(
        url,
        data: {'content': content, 'message_type': messageType},
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to send message'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Mark messages as read
  Future<Map<String, dynamic>> markMessagesAsRead({
    required int conversationId,
  }) async {
    try {
      String url =
          '${AppConstants.baseUrl}chat/conversations/$conversationId/mark_messages_read/';

      final response = await _dio.post(
        url,
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to mark messages as read'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Close/resolve a conversation
  Future<Map<String, dynamic>> closeConversation({
    required int conversationId,
  }) async {
    try {
      String url =
          '${AppConstants.baseUrl}chat/conversations/$conversationId/close/';

      final response = await _dio.post(
        url,
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to close conversation'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get unread message count
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      String url = '${AppConstants.baseUrl}chat/conversations/unread_count/';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'application/json',
        ),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fetch unread count'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
