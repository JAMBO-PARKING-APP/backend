import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        title: const Text('Support Chat'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat with our support team for help'),
                ),
              );
            },
          ),
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
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _openNewConversation,
                    icon: const Icon(Icons.add),
                    label: const Text('Start New Conversation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String?>(
                          value: selectedStatus,
                          isExpanded: true,
                          hint: const Text('Filter by status'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Statuses'),
                            ),
                            const DropdownMenuItem(
                              value: 'open',
                              child: Text('Open'),
                            ),
                            const DropdownMenuItem(
                              value: 'in_progress',
                              child: Text('In Progress'),
                            ),
                            const DropdownMenuItem(
                              value: 'resolved',
                              child: Text('Resolved'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => selectedStatus = value);
                            _fetchConversations();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        onPressed: _openNewConversation,
                        backgroundColor: Colors.blue.shade700,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                ...conversations.map((conversation) {
                  final status = conversation['status'] ?? 'unknown';
                  final statusColor = status == 'open'
                      ? Colors.orange
                      : status == 'in_progress'
                      ? Colors.blue
                      : Colors.green;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Card(
                      elevation: 2,
                      child: ListTile(
                        onTap: () => _openConversation(conversation),
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          conversation['subject'] ?? 'Untitled',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              conversation['category'] ?? 'Other',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (conversation['last_message'] != null)
                              Text(
                                conversation['last_message']['content'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (conversation['unread_count'] != null &&
                                conversation['unread_count'] > 0)
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Text(
                                  '${conversation['unread_count']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
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
  late TextEditingController messageController;
  List<dynamic> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    chatService = ChatService();
    messageController = TextEditingController();
    _fetchMessages();
    _markAsRead();
    // Start polling for real-time messages (every 3 seconds)
    _startPolling();
  }

  @override
  void dispose() {
    messageController.dispose();
    chatService.stopPolling(); // Stop polling when screen is closed
    chatService.dispose();
    super.dispose();
  }

  void _startPolling() {
    chatService.startPolling(widget.conversation['id'], (data) {
      if (mounted) {
        setState(() {
          messages = data['results'] ?? data;
        });
      }
    });
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
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to send message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation['subject'] ?? 'Conversation',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.conversation['agent_name'] ?? 'Support Team'} - ${widget.conversation['status']}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Start the conversation.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isMe =
                          message['sender_name'] !=
                          widget.conversation['agent_name'];

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['sender_name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(message['content'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('HH:mm').format(
                                    DateTime.parse(message['created_at']),
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.blue.shade700,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
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
  String selectedCategory = 'other';
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
        category: selectedCategory,
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
