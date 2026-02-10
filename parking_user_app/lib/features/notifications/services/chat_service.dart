import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../core/api_client.dart';

class ChatService {
  final ApiClient _apiClient;
  Timer? _pollTimer;
  static const int pollIntervalSeconds =
      3; // Poll every 3 seconds for real-time updates

  ChatService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Start polling for new messages (real-time simulation)
  void startPolling(
    String conversationId,
    Function(Map<String, dynamic>) onUpdate,
  ) {
    stopPolling();
    _pollTimer = Timer.periodic(Duration(seconds: pollIntervalSeconds), (
      _,
    ) async {
      final result = await getMessages(conversationId: conversationId);
      if (result['success']) {
        onUpdate(result['data']);
      }
    });
  }

  /// Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Get all chat conversations for the user
  Future<Map<String, dynamic>> getConversations({
    int page = 1,
    String? status,
  }) async {
    try {
      Map<String, dynamic> queryParams = {'page': page};

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _apiClient.get(
        'chat/conversations/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fetch conversations'};
    } catch (e) {
      debugPrint('[ChatService] Error fetching conversations: $e');
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
      final response = await _apiClient.post(
        'chat/conversations/',
        data: {'subject': subject, 'category': category, 'priority': priority},
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to create conversation'};
    } catch (e) {
      debugPrint('[ChatService] Error creating conversation: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMessages({
    required String conversationId,
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        'chat/conversations/$conversationId/messages/',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fetch messages'};
    } catch (e) {
      debugPrint('[ChatService] Error fetching messages: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await _apiClient.post(
        'chat/conversations/$conversationId/send_message/',
        data: {'content': content, 'message_type': messageType},
      );

      if (response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to send message'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markMessagesAsRead({
    required String conversationId,
  }) async {
    try {
      final response = await _apiClient.post(
        'chat/conversations/$conversationId/mark_messages_read/',
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to mark messages as read'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> closeConversation({
    required String conversationId,
  }) async {
    try {
      final response = await _apiClient.post(
        'chat/conversations/$conversationId/close/',
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
      final response = await _apiClient.get('chat/conversations/unread_count/');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fetch unread count'};
    } catch (e) {
      debugPrint('[ChatService] Error fetching unread count: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Dispose chat service (cleanup timers and resources)
  void dispose() {
    stopPolling();
  }
}
