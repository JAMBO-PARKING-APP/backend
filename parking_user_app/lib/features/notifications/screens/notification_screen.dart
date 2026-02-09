import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () =>
                context.read<NotificationProvider>().markAllAsRead(),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = provider.notifications[index];
                final type = note.category;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: note.isRead
                          ? Colors.grey.shade100
                          : Theme.of(context).primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getBgColor(type),
                      child: Icon(
                        _getIcon(type),
                        color: _getColor(type),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: note.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(note.message),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('MMM dd, HH:mm').format(note.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getBgColor(String category) {
    switch (category) {
      case 'violations':
        return Colors.red.shade50;
      case 'payments':
        return Colors.green.shade50;
      case 'promo':
        return Colors.purple.shade50;
      case 'reservations':
        return Colors.orange.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _getColor(String category) {
    switch (category) {
      case 'violations':
        return Colors.red;
      case 'payments':
        return Colors.green;
      case 'promo':
        return Colors.purple;
      case 'reservations':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getIcon(String category) {
    switch (category) {
      case 'violations':
        return Icons.warning_amber_rounded;
      case 'payments':
        return Icons.account_balance_wallet;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'reservations':
        return Icons.calendar_today;
      default:
        return Icons.notifications_none;
    }
  }
}
