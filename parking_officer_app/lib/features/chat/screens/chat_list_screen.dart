import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/chat/providers/chat_provider.dart';
import 'package:parking_officer_app/features/chat/screens/chat_detail_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Chats')),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.conversations.isEmpty) {
            return const Center(child: Text('No active conversations'));
          }

          return RefreshIndicator(
            onRefresh: chatProvider.fetchConversations,
            child: ListView.builder(
              itemCount: chatProvider.conversations.length,
              itemBuilder: (context, index) {
                final convo = chatProvider.conversations[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    convo.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    convo.lastMessage ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(convo.lastMessageTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (convo.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${convo.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatDetailScreen(conversation: convo),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
