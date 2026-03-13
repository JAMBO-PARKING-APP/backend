import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking_officer_app/features/parking/models/parking_session_model.dart';
import 'package:parking_officer_app/features/violations/screens/violation_form_screen.dart';
import 'package:parking_officer_app/core/app_theme.dart';

class SessionDetailScreen extends StatefulWidget {
  final ParkingSession session;
  final String zoneId;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.zoneId,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = widget.session.plannedEndTime.isBefore(now);
    final remaining = widget.session.plannedEndTime.difference(now);

    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVehicleHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(context, isExpired, remaining),
            const SizedBox(height: 24),
            _buildDetailRow('Zone', widget.session.zoneName ?? 'N/A'),
            _buildDetailRow('Slot', widget.session.slotCode ?? 'N/A'),
            _buildDetailRow(
              'Start Time',
              DateFormat('MMM d, h:mm a').format(widget.session.startTime),
            ),
            _buildDetailRow(
              'Planned End',
              DateFormat('MMM d, h:mm a').format(widget.session.plannedEndTime),
            ),
            _buildDetailRow(
              'Duration',
              '${widget.session.durationMinutes} minutes',
            ),
            _buildDetailRow(
              'Amount Due',
              'UGX ${widget.session.amountDue.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 40),

            if (!isExpired) const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViolationFormScreen(
                      vehiclePlate: widget.session.vehiclePlate,
                      zoneId: widget.zoneId,
                      sessionId: widget.session.id,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'ISSUE VIOLATION',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'VEHICLE PLATE',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.session.vehiclePlate,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isExpired,
    Duration remaining,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: isExpired ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'SESSION EXPIRED' : 'ACTIVE SESSION',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  isExpired
                      ? 'Expired ${DateFormat('h:mm a').format(widget.session.plannedEndTime)}'
                      : '${remaining.inMinutes} minutes remaining',
                  style: TextStyle(
                    color: isExpired
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
