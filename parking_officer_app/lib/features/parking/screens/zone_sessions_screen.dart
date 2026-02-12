import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/models/parking_session_model.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:intl/intl.dart';

class ZoneSessionsScreen extends StatefulWidget {
  final Zone zone;

  const ZoneSessionsScreen({super.key, required this.zone});

  @override
  State<ZoneSessionsScreen> createState() => _ZoneSessionsScreenState();
}

class _ZoneSessionsScreenState extends State<ZoneSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZoneProvider>().selectZone(widget.zone.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zone.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ZoneProvider>().selectZone(widget.zone.id);
            },
          ),
        ],
      ),
      body: Consumer<ZoneProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.activeSessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_parking, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No active sessions in ${widget.zone.name}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      context.read<ZoneProvider>().selectZone(widget.zone.id);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<ZoneProvider>().selectZone(widget.zone.id),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.activeSessions.length,
              itemBuilder: (context, index) {
                final session = provider.activeSessions[index];
                return _SessionCard(session: session);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ParkingSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expiryTime = session.plannedEndTime;
    final timeRemaining = expiryTime.difference(now);
    final isExpiringSoon = timeRemaining.inMinutes < 15;
    final isExpired = timeRemaining.isNegative;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    session.vehiclePlate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red.withValues(alpha: 0.1)
                        : isExpiringSoon
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExpired
                          ? Colors.red
                          : isExpiringSoon
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                  child: Text(
                    isExpired ? 'EXPIRED' : 'ACTIVE',
                    style: TextStyle(
                      color: isExpired
                          ? Colors.red
                          : isExpiringSoon
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Driver Info
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.driverName ?? 'Unknown Driver',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Time Info
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Started: ${DateFormat('HH:mm').format(session.startTime)}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  'Expires: ${DateFormat('HH:mm').format(expiryTime)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isExpiringSoon ? Colors.orange : Colors.grey,
                    fontWeight: isExpiringSoon
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Time Remaining
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: isExpired
                        ? 1.0
                        : 1 -
                              (timeRemaining.inMinutes /
                                  session.startTime
                                      .difference(expiryTime)
                                      .inMinutes
                                      .abs()),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isExpired
                          ? Colors.red
                          : isExpiringSoon
                          ? Colors.orange
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isExpired
                      ? 'Overdue'
                      : '${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isExpired
                        ? Colors.red
                        : isExpiringSoon
                        ? Colors.orange
                        : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),

            // Slot Info (if available)
            if (session.slotNumber != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.local_parking, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Slot: ${session.slotNumber}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
