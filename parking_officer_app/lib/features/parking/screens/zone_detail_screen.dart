import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/parking/providers/zone_provider.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/screens/scanner_screen.dart';
import 'package:parking_officer_app/features/violations/screens/violation_form_screen.dart';
import 'package:parking_officer_app/core/app_theme.dart';

class ZoneDetailScreen extends StatefulWidget {
  final Zone zone;
  const ZoneDetailScreen({super.key, required this.zone});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
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
      appBar: AppBar(title: Text(widget.zone.name)),
      body: Consumer<ZoneProvider>(
        builder: (context, zoneProvider, _) {
          if (zoneProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final zone = zoneProvider.selectedZone ?? widget.zone;
          final sessions = zoneProvider.activeSessions;

          return Column(
            children: [
              _buildZoneSummary(zone),
              _buildActions(context, zone),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Text(
                      'Active Sessions (${sessions.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: sessions.isEmpty
                    ? const Center(
                        child: Text('No active sessions in this zone'),
                      )
                    : ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.directions_car),
                            ),
                            title: Text(
                              session.vehiclePlate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Slot: ${session.slotCode ?? 'N/A'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Session details coming soon'),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildZoneSummary(Zone zone) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total', value: '${zone.totalSlots}'),
          _StatItem(
            label: 'Occupied',
            value: '${zone.occupiedSlots}',
            color: Colors.blue,
          ),
          _StatItem(
            label: 'Available',
            value: '${zone.availableSlots}',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Zone zone) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScannerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('SCAN QR'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final plate = await _showSearchDialog(context);
                if (plate != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViolationFormScreen(
                        vehiclePlate: plate,
                        zoneId: zone.id,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.search),
              label: const Text('SEARCH PLATE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showSearchDialog(BuildContext context) async {
    String? plate;
    TextEditingController plateController = TextEditingController();

    return showDialog<String?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Search Vehicle Plate'),
          content: TextField(
            controller: plateController,
            decoration: const InputDecoration(
              hintText: 'Enter vehicle plate',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              plate = value.toUpperCase();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Search'),
              onPressed: () {
                Navigator.of(dialogContext).pop(plate);
              },
            ),
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
