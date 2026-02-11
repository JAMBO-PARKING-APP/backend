import 'package:flutter/material.dart';
import 'package:parking_officer_app/features/chat/models/chat_model.dart';
import 'package:parking_officer_app/features/chat/services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatConversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();
    _conversations = await _chatService.getConversations();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(String conversationId) async {
    _isLoading = true;
    notifyListeners();
    _messages = await _chatService.getMessages(conversationId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage(String conversationId, String content) async {
    final success = await _chatService.sendMessage(conversationId, content);
    if (success) {
      await fetchMessages(conversationId);
    }
    return success;
  }
}
