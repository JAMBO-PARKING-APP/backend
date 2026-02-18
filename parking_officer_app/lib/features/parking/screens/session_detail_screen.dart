import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking_officer_app/features/parking/models/parking_session_model.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/features/violations/screens/violation_form_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  final ParkingSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired =
        session.status == 'expired' || session.plannedEndTime.isBefore(now);

    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle & Status Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        session.vehiclePlate,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusBadge(session, isExpired),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Driver Information
            _buildSectionTitle('Driver Information'),
            Card(
              child: Column(
                children: [
                  _DetailTile(
                    icon: Icons.person,
                    label: 'Name',
                    value: session.driverName ?? 'Unknown',
                  ),
                  const Divider(height: 1),
                  _DetailTile(
                    icon: Icons.phone,
                    label: 'Phone Number',
                    value: session.driverPhone ?? 'Not Available',
                    trailing: session.driverPhone != null
                        ? IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () {
                              // Handle call action
                            },
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timing Information
            _buildSectionTitle('Session Timeline'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TimelineItem(
                      icon: Icons.play_circle_outline,
                      label: 'Started At',
                      value: DateFormat(
                        'MMM d, yyyy HH:mm',
                      ).format(session.startTime),
                      color: Colors.blue,
                    ),
                    const _TimelineConnector(),
                    _TimelineItem(
                      icon: Icons.timer_outlined,
                      label: 'Planned End',
                      value: DateFormat(
                        'MMM d, yyyy HH:mm',
                      ).format(session.plannedEndTime),
                      color: isExpired ? Colors.red : Colors.orange,
                    ),
                    if (session.actualEndTime != null) ...[
                      const _TimelineConnector(),
                      _TimelineItem(
                        icon: Icons.stop_circle_outlined,
                        label: 'Actually Ended',
                        value: DateFormat(
                          'MMM d, yyyy HH:mm',
                        ).format(session.actualEndTime!),
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location & Payment
            _buildSectionTitle('Location & Cost'),
            Card(
              child: Column(
                children: [
                  _DetailTile(
                    icon: Icons.location_on,
                    label: 'Parking Zone',
                    value: session.zoneName ?? 'N/A',
                  ),
                  const Divider(height: 1),
                  _DetailTile(
                    icon: Icons.grid_view,
                    label: 'Slot',
                    value:
                        session.slotNumber ??
                        session.slotCode ??
                        'Automatic/Mixed',
                  ),
                  const Divider(height: 1),
                  _DetailTile(
                    icon: Icons.payments_outlined,
                    label: 'Estimated Cost',
                    value: 'UGX ${session.amountDue.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            if (isExpired && session.status != 'completed')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViolationFormScreen(
                        vehiclePlate: session.vehiclePlate,
                        sessionId: session.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('ISSUE VIOLATION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ParkingSession session, bool isExpired) {
    Color color = Colors.green;
    String text = session.status.toUpperCase();

    if (isExpired) {
      color = Colors.red;
      text = 'EXPIRED';
    } else if (session.status == 'active') {
      color = Colors.green;
    } else if (session.status == 'completed') {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      trailing: trailing,
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      margin: const EdgeInsets.only(left: 13),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.grey,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }
}
