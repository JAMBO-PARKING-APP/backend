import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants.dart';
import '../services/chat_service.dart';

class ChatConversationListScreen extends StatefulWidget {
  const ChatConversationListScreen({super.key});

  @override
  State<ChatConversationListScreen> createState() =>
      _ChatConversationListScreenState();
}

class _ChatConversationListScreenState
    extends State<ChatConversationListScreen> {
  late ChatService chatService;
  List<dynamic> conversations = [];
  bool isLoading = false;
  int currentPage = 1;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    chatService = ChatService();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    setState(() => isLoading = true);
    try {
      final result = await chatService.getConversations(
        page: currentPage,
        status: selectedStatus,
      );

      if (result['success']) {
        setState(() {
          conversations = result['data']['results'] ?? [];
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error loading conversations'),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openNewConversation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewChatScreen()),
    ).then((_) => _fetchConversations());
  }

  void _openConversation(dynamic conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(conversation: conversation),
      ),
    ).then((_) => _fetchConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        elevation: 0,
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: isLoading && conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 80,
                endIndent: 16,
                color: Color(0xFFE5E5E5),
              ),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final lastMessage = conversation['last_message'];
                final unreadCount = conversation['unread_count'] ?? 0;
                final timeStr = lastMessage != null
                    ? _formatTime(DateTime.parse(lastMessage['created_at']))
                    : '';

                return ListTile(
                  onTap: () => _openConversation(conversation),
                  leading: const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFE5E5E5),
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  title: Text(
                    conversation['subject'] ?? 'Help Request',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage != null
                        ? lastMessage['content']
                        : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? const Color(0xFF25D366)
                              : Colors.black54,
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 22),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewConversation,
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return DateFormat('HH:mm').format(time);
    } else if (time.day == now.day - 1 &&
        time.month == now.month &&
        time.year == now.year) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }
}

// Screen for viewing a specific chat conversation

class ChatDetailScreen extends StatefulWidget {
  final dynamic conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late ChatService chatService;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  WebSocketChannel? _channel;
  List<dynamic> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    chatService = ChatService();
    _fetchMessages();
    _markAsRead();
    _initWebSocket();
  }

  void _initWebSocket() async {
    final baseUrl = AppConstants.wsUrl;
    final convId = widget.conversation['id'];

    // We don't have JWT auth in WS yet, but we'll connect
    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse('$baseUrl/chat/$convId/'),
      );

      _channel!.stream.listen((data) {
        final message = jsonDecode(data);
        if (mounted) {
          setState(() {
            // Check if message already exists to avoid duplicates if polling is still on
            final exists = messages.any((m) => m['id'] == message['id']);
            if (!exists) {
              messages.insert(0, message);
              _scrollToBottom();
            }
          });
        }
      });
    } catch (e) {
      debugPrint('[ChatDetailScreen] WS Error: $e');
    }
  }

  @override
  void dispose() {
    messages.clear();
    _channel?.sink.close();
    messageController.dispose();
    scrollController.dispose();
    chatService.stopPolling();
    chatService.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    setState(() => isLoading = true);
    try {
      final result = await chatService.getMessages(
        conversationId: widget.conversation['id'],
      );

      if (result['success']) {
        setState(() {
          messages = result['data']['results'] ?? result['data'];
        });
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    await chatService.markMessagesAsRead(
      conversationId: widget.conversation['id'],
    );
  }

  Future<void> _sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    messageController.clear();

    final result = await chatService.sendMessage(
      conversationId: widget.conversation['id'],
      content: content,
    );

    if (result['success']) {
      await _fetchMessages();
      _scrollToBottom();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to send message')),
      );
    }
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // WhatsApp Background Color
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation['agent_name'] ?? 'Support Agent',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.conversation['status'] ?? 'Active',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
        backgroundColor: const Color(0xFF075E54), // WhatsApp Dark Green
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png',
            ),
            opacity: 0.08,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: isLoading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Messages are end-to-end encrypted.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 20,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        final isMe =
                            message['sender_name'] !=
                            widget.conversation['agent_name'];

                        // Check if date header should be shown
                        bool showDate = false;
                        if (index == messages.length - 1) {
                          showDate = true;
                        } else {
                          final prevMessage =
                              messages[messages.length - 2 - index];
                          final date = DateTime.parse(message['created_at']);
                          final prevDate = DateTime.parse(
                            prevMessage['created_at'],
                          );
                          if (date.day != prevDate.day) {
                            showDate = true;
                          }
                        }

                        return Column(
                          children: [
                            if (showDate)
                              _buildDateHeader(
                                DateTime.parse(message['created_at']),
                              ),
                            _buildMessageBubble(message, isMe),
                          ],
                        );
                      },
                    ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    String formattedDate = '';
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      formattedDate = 'TODAY';
    } else if (date.day == now.day - 1 &&
        date.month == now.month &&
        date.year == now.year) {
      formattedDate = 'YESTERDAY';
    } else {
      formattedDate = DateFormat('MMMM dd, yyyy').format(date).toUpperCase();
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD1E4F0),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2, top: 2),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe
                ? const Radius.circular(12)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 60, bottom: 4),
              child: Text(
                message['content'] ?? '',
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat(
                      'HH:mm',
                    ).format(DateTime.parse(message['created_at'])),
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 14, color: Colors.blue),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(
              backgroundColor: Color(0xFF128C7E),
              child: Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Screen for creating a new support conversation
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  late ChatService chatService;
  late TextEditingController subjectController;
  // List of support categories
  // We'll hardcode to 'Support Request' in the UI
  final String selectedCategory = 'technical';
  String selectedPriority = 'medium';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    chatService = ChatService();
    subjectController = TextEditingController();
  }

  @override
  void dispose() {
    subjectController.dispose();
    super.dispose();
  }

  Future<void> _createConversation() async {
    if (subjectController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a subject')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await chatService.createConversation(
        subject: subjectController.text,
        category: selectedCategory, // Use the hardcoded category
        priority: selectedPriority,
      );

      if (result['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation created successfully')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create conversation'),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start New Conversation'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        hintText: 'Describe your issue...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Removed the Category Card as per instruction
            /*
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'parking',
                          child: Text('Parking'),
                        ),
                        DropdownMenuItem(
                          value: 'payment',
                          child: Text('Payment'),
                        ),
                        DropdownMenuItem(
                          value: 'violation',
                          child: Text('Violation'),
                        ),
                        DropdownMenuItem(
                          value: 'subscription',
                          child: Text('Subscription'),
                        ),
                        DropdownMenuItem(
                          value: 'account',
                          child: Text('Account'),
                        ),
                        DropdownMenuItem(
                          value: 'technical',
                          child: Text('Technical'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedCategory = value ?? 'other');
                      },
                    ),
                  ],
                ),
              ),
            ),
            */
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Priority',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedPriority,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Text('Urgent'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedPriority = value ?? 'medium');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _createConversation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    )
                  : const Text(
                      'Start Conversation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
