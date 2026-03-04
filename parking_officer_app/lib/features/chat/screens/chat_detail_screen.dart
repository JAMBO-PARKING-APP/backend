import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/chat/providers/chat_provider.dart';
import 'package:parking_officer_app/features/chat/models/chat_model.dart';
import 'package:parking_officer_app/features/auth/providers/auth_provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:parking_officer_app/core/constants.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchMessages(widget.conversation.id);
      _initWebSocket();
    });
  }

  void _initWebSocket() {
    final baseUrl = AppConstants.wsUrl;
    final convId = widget.conversation.id;

    try {
      _channel = WebSocketChannel.connect(Uri.parse('$baseUrl/chat/$convId/'));

      _channel!.stream.listen((data) {
        final messageData = jsonDecode(data);
        final message = ChatMessage.fromJson(messageData);
        if (mounted) {
          context.read<ChatProvider>().addRealtimeMessage(message);
        }
      });
    } catch (e) {
      debugPrint('[ChatDetailScreen] WS Error: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    super.dispose();
  }

  void _send() async {
    if (_messageController.text.isEmpty) return;
    final success = await context.read<ChatProvider>().sendMessage(
      widget.conversation.id,
      _messageController.text,
    );
    if (success) _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.conversation.userName), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, cp, _) {
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: cp.messages.length,
                  itemBuilder: (context, index) {
                    final msg = cp.messages[cp.messages.length - 1 - index];
                    final isMe = msg.senderId == myId;
                    return _MessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a response...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primaryColor),
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
