import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/enforcement/providers/officer_provider.dart';
import 'package:intl/intl.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<OfficerProvider>().fetchQRScans();
    context.read<OfficerProvider>().fetchActivityLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scans', icon: Icon(Icons.qr_code_scanner)),
            Tab(text: 'Activity', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildScansTab(), _buildActivityTab()],
      ),
    );
  }

  Widget _buildScansTab() {
    return Consumer<OfficerProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.qrScans.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.qrScans.isEmpty) {
          return _buildEmptyState('No scans yet', Icons.qr_code_2);
        }

        return RefreshIndicator(
          onRefresh: () async => provider.fetchQRScans(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.qrScans.length,
            itemBuilder: (context, index) {
              final scan = provider.qrScans[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(
                      scan.scanStatus,
                    ).withValues(alpha: 0.1),
                    child: Icon(
                      _getStatusIcon(scan.scanStatus),
                      color: _getStatusColor(scan.scanStatus),
                    ),
                  ),
                  title: Text(
                    scan.vehiclePlate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${scan.zoneName}\n${_formatTime(scan.createdAt)}',
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        scan.scanStatus,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      scan.scanStatus.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(scan.scanStatus),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActivityTab() {
    return Consumer<OfficerProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.activityLogs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.activityLogs.isEmpty) {
          return _buildEmptyState(
            'No activity logged',
            Icons.history_toggle_off,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => provider.fetchActivityLogs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.activityLogs.length,
            itemBuilder: (context, index) {
              // Note: QRCodeScan model is reused for Activity Logs in OfficerProvider
              // which might be a bit confusing but we'll work with its JSON mapping
              final log = provider.activityLogs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.info_outline, color: Colors.white),
                  ),
                  title: Text(
                    _formatAction(
                      log.scanStatus,
                    ), // action field mapped to scanStatus
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${_formatDetails(log.zoneName)}\n${_formatTime(log.createdAt)}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatAction(String action) {
    return action.replaceAll('_', ' ').toUpperCase();
  }

  String _formatDetails(String details) {
    if (details.isEmpty) return 'No additional details';
    return details;
  }

  String _formatTime(DateTime time) {
    return DateFormat('MMM d, HH:mm').format(time);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return Colors.green;
      case 'expired':
        return Colors.orange;
      case 'invalid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return Icons.check_circle;
      case 'expired':
        return Icons.timer;
      case 'invalid':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}
