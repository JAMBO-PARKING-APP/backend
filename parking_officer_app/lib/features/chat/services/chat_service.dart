import 'package:parking_officer_app/core/api_client.dart';
import 'package:parking_officer_app/features/chat/models/chat_model.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ChatConversation>> getConversations() async {
    try {
      final response = await _apiClient.get(
        'notifications/chat/conversations/',
      );
      if (response.statusCode == 200) {
        final List data = (response.data is Map)
            ? response.data['results']
            : response.data;
        return data.map((c) => ChatConversation.fromJson(c)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final response = await _apiClient.get(
        'notifications/chat/conversations/$conversationId/messages/',
      );
      if (response.statusCode == 200) {
        final List data = (response.data is Map)
            ? response.data['results']
            : response.data;
        return data.map((m) => ChatMessage.fromJson(m)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    try {
      final response = await _apiClient.post(
        'notifications/chat/conversations/$conversationId/send_message/',
        data: {'content': content},
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
