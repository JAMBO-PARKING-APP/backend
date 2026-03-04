import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/enforcement/providers/officer_provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('ACTIVITY LOGS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
          tabs: const [
            Tab(text: 'SCANS'),
            Tab(text: 'ACTIVITY'),
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
          return _buildEmptyState('NO SCANS DETECTED', Icons.qr_code_2_rounded);
        }

        return RefreshIndicator(
          onRefresh: () async => provider.fetchQRScans(),
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: provider.qrScans.length,
            itemBuilder: (context, index) {
              final scan = provider.qrScans[index];
              return _buildTimelineItem(
                scan.vehiclePlate,
                scan.zoneName,
                _formatTime(scan.createdAt),
                _getStatusIcon(scan.scanStatus),
                _getStatusColor(scan.scanStatus),
                isLast: index == provider.qrScans.length - 1,
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
          return _buildEmptyState('NO ACTIONS LOGGED', Icons.history_rounded);
        }

        return RefreshIndicator(
          onRefresh: () async => provider.fetchActivityLogs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: provider.activityLogs.length,
            itemBuilder: (context, index) {
              final log = provider.activityLogs[index];
              return _buildTimelineItem(
                _formatAction(log.scanStatus),
                _formatDetails(log.zoneName),
                _formatTime(log.createdAt),
                Icons.bolt_rounded,
                AppTheme.primaryColor,
                isLast: index == provider.activityLogs.length - 1,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey[200])),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 2.0,
            ),
          ),
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
    return DateFormat('HH:mm').format(time);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return AppTheme.successColor;
      case 'expired':
        return AppTheme.warningColor;
      case 'invalid':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return Icons.verified_rounded;
      case 'expired':
        return Icons.timer_outlined;
      case 'invalid':
        return Icons.gavel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
