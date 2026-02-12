import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';
import 'package:parking_user_app/features/parking/providers/zone_provider.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/features/auth/models/vehicle_model.dart';
import 'package:parking_user_app/widgets/payment_selection_dialog.dart';
import 'package:parking_user_app/features/parking/screens/parking_map_screen.dart';
import 'package:parking_user_app/features/payments/services/payment_service.dart';

class ZoneListScreen extends StatefulWidget {
  const ZoneListScreen({super.key});

  @override
  State<ZoneListScreen> createState() => _ZoneListScreenState();
}

class _ZoneListScreenState extends State<ZoneListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZoneProvider>().fetchZones();
    });
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  void _showStartParkingDialog(BuildContext context, Zone zone) {
    TimeOfDay endTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 1)),
    );
    final vehicles = context.read<AuthProvider>().user?.vehicles ?? [];
    Vehicle? selectedVehicle = vehicles.isNotEmpty ? vehicles.first : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final now = TimeOfDay.now();
          final startMinutes = now.hour * 60 + now.minute;
          final endMinutes = endTime.hour * 60 + endTime.minute;

          // Handle next day wrap-around roughly for display if needed,
          // but for simple parking we assume same day or handled by logic
          int durationMinutes = endMinutes - startMinutes;
          if (durationMinutes <= 0) durationMinutes += 24 * 60; // Next day

          final durationHours = durationMinutes / 60.0;
          final estimatedCost = zone.hourlyRate * durationHours;

          return AlertDialog(
            title: Text('Start Parking: ${zone.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rate: UGX ${zone.hourlyRate.toInt()}/hr'),
                const SizedBox(height: 16),
                const Text('Select Vehicle:'),
                vehicles.isEmpty
                    ? const Text(
                        'No vehicles found. Please add one in profile.',
                        style: TextStyle(color: Colors.red),
                      )
                    : DropdownButton<Vehicle>(
                        value: selectedVehicle,
                        isExpanded: true,
                        onChanged: (val) =>
                            setState(() => selectedVehicle = val),
                        items: vehicles.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Text(v.displayName),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 16),
                const Text(
                  'End Time:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (time != null) {
                      setState(() => endTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          endTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Duration: ${durationHours.toStringAsFixed(1)} hrs',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  'Est. Cost: UGX ${estimatedCost.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedVehicle == null
                    ? null
                    : () {
                        Navigator.pop(context); // Close dialog

                        // Show payment selection dialog
                        final walletBalance =
                            context.read<AuthProvider>().user?.walletBalance ??
                            0.0;

                        showDialog(
                          context: context,
                          builder: (context) => PaymentSelectionDialog(
                            amount: estimatedCost,
                            walletBalance: walletBalance,
                            onWalletSelected: () async {
                              await _processPayment(
                                context,
                                zone,
                                selectedVehicle!,
                                durationHours,
                                isWallet: true,
                              );
                            },
                            onPesapalSelected: () async {
                              await _processPayment(
                                context,
                                zone,
                                selectedVehicle!,
                                durationHours,
                                isWallet: false,
                              );
                            },
                          ),
                        );
                      },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    Zone zone,
    Vehicle vehicle,
    double durationHours, {
    required bool isWallet,
  }) async {
    if (isWallet) {
      final success = await context.read<ParkingProvider>().startParking(
        context: context,
        zoneId: zone.id,
        vehicleId: vehicle.id,
        durationHours: durationHours,
      );
      if (context.mounted && success) {
        _showSuccessDialog(context, zone);
      }
    } else {
      // Pesapal Flow
      final success = await context.read<ParkingProvider>().startParking(
        context: context,
        zoneId: zone.id,
        vehicleId: vehicle.id,
        durationHours: durationHours,
      );

      if (context.mounted && success) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final paymentService = PaymentService();
          final result = await paymentService.initiatePesapalPayment(
            amount: zone.hourlyRate * durationHours,
            description: 'Parking - ${zone.name}',
            isWalletTopup: true,
          );

          if (mounted) Navigator.pop(context); // Hide loading

          if (result['success'] == true && mounted) {
            final url = result['redirect_url'];
            if (url != null) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Payment initiation failed'),
              ),
            );
          }
        } catch (e) {
          if (mounted) Navigator.pop(context); // Hide loading on error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error initiating payment: $e')),
            );
          }
        }
      }
    }
  }

  void _showSuccessDialog(BuildContext context, Zone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Payment Complete!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your session in ${zone.name} is now active.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close payment selection if open
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parking Zones')),
      body: Consumer<ZoneProvider>(
        builder: (context, zoneProvider, _) {
          if (zoneProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: zoneProvider.zones.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final zone = zoneProvider.zones[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showStartParkingDialog(context, zone),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    zone.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rate: UGX ${zone.hourlyRate.toInt()}/hr',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${zone.code} - ${zone.availableSlots}/${zone.totalSlots} slots',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.map, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ParkingMapScreen(initialZone: zone),
                                  ),
                                );
                              },
                              tooltip: 'View on Map',
                            ),
                          ],
                        ),
                        const Divider(),
                        TextButton.icon(
                          onPressed: () =>
                              _launchMaps(zone.latitude, zone.longitude),
                          icon: const Icon(Icons.directions),
                          label: const Text('Get Directions'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
