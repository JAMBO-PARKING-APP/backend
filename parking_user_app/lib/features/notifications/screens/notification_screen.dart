import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking_user_app/features/notifications/providers/notification_provider.dart';
import 'package:provider/provider.dart';

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
      context.read<NotificationProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.fetchAll,
        child: provider.isLoading && provider.notifications.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : provider.errorMessage != null && provider.notifications.isEmpty
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(provider.errorMessage!),
                  ),
                ],
              )
            : provider.notifications.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: 300,
                    child: Center(child: Text('No notifications yet.')),
                  ),
                ],
              )
            : ListView.separated(
                itemCount: provider.notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  return ListTile(
                    leading: Icon(
                      notification.isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                    ),
                    title: Text(notification.title),
                    subtitle: Text(
                      '${notification.message}\n'
                      '${DateFormat('d MMM y, HH:mm').format(notification.createdAt.toLocal())}',
                    ),
                    isThreeLine: true,
                    onTap: notification.isRead
                        ? null
                        : () => provider.markRead(notification),
                  );
                },
              ),
      ),
    );
  }
}
