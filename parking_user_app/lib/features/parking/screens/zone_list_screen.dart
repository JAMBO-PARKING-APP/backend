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
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/payments/screens/pesapal_webview_screen.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/features/parking/screens/active_session_screen.dart';

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
      PaymentService().preWarmPesapal(); // Pre-fetch Pesapal token
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
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) => Text(
                    'Rate: ${CurrencyFormatter.formatCurrency(zone.hourlyRate, settings.countryConfig)}/hr',
                  ),
                ),
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
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) => Text(
                    'Est. Cost: ${CurrencyFormatter.formatCurrency(estimatedCost, settings.countryConfig)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                              Navigator.pop(
                                context,
                              ); // Close PaymentSelectionDialog
                              final confirmed = await _showConfirmSessionDialog(
                                context,
                                zone,
                                selectedVehicle!,
                                durationHours,
                                estimatedCost,
                              );
                              if (confirmed) {
                                await _processPayment(
                                  zone,
                                  selectedVehicle!,
                                  durationHours,
                                  isWallet: true,
                                );
                              }
                            },
                            onPesapalSelected: () async {
                              Navigator.pop(
                                context,
                              ); // Close PaymentSelectionDialog
                              final confirmed = await _showConfirmSessionDialog(
                                context,
                                zone,
                                selectedVehicle!,
                                durationHours,
                                estimatedCost,
                              );
                              if (confirmed) {
                                await _processPayment(
                                  zone,
                                  selectedVehicle!,
                                  durationHours,
                                  isWallet: false,
                                );
                              }
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

  Future<bool> _showConfirmSessionDialog(
    BuildContext context,
    Zone zone,
    Vehicle vehicle,
    double durationHours,
    double cost,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Session'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to start this parking session?',
                ),
                const SizedBox(height: 16),
                _buildConfirmRow('Zone', zone.name),
                _buildConfirmRow('Vehicle', vehicle.displayName),
                _buildConfirmRow(
                  'Duration',
                  '${durationHours.toStringAsFixed(1)} hrs',
                ),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) => _buildConfirmRow(
                    'Cost',
                    CurrencyFormatter.formatCurrency(
                      cost,
                      settings.countryConfig,
                    ),
                    isBold: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm & Start'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildConfirmRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(
    Zone zone,
    Vehicle vehicle,
    double durationHours, {
    required bool isWallet,
  }) async {
    if (isWallet) {
      DialogService.showLoading(message: 'Starting session...');

      try {
        final parkingProvider = context.read<ParkingProvider>();
        final session = await parkingProvider.startParking(
          context: context,
          zoneId: zone.id,
          vehicleId: vehicle.id,
          durationHours: durationHours,
          paymentMethod: 'wallet',
        );

        DialogService.hideLoading();

        if (mounted && session != null) {
          _showSuccessDialog(context, zone, session);
        }
      } catch (e) {
        DialogService.hideLoading();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error starting session: $e')));
        }
      }
    } else {
      debugPrint('[PesapalFlow] Starting Pesapal flow...');
      DialogService.showLoading(message: 'Preparing session...');
      try {
        debugPrint('[PesapalFlow] Calling startParking...');
        final session = await context.read<ParkingProvider>().startParking(
          context: context,
          zoneId: zone.id,
          vehicleId: vehicle.id,
          durationHours: durationHours,
          paymentMethod: 'pesapal',
        );

        if (session != null) {
          debugPrint('[PesapalFlow] Session prepared: ${session.id}');
          DialogService.showLoading(message: 'Securing payment session...');
          final paymentService = PaymentService();
          debugPrint('[PesapalFlow] Calling initiatePesapalPayment...');
          final result = await paymentService.initiatePesapalPayment(
            amount: zone.hourlyRate * durationHours,
            description: 'Parking - ${zone.name}',
            isWalletTopup: false,
            parkingSessionId: session.id,
          );
          debugPrint(
            '[PesapalFlow] initiatePesapalPayment result success: ${result['success']}',
          );

          if (result['success'] == true && mounted) {
            final url = result['redirect_url'];
            debugPrint(
              '[PesapalFlow] Redirect URL: ${url != null ? "FOUND" : "NULL"}',
            );
            if (url != null) {
              DialogService.showLoading(message: 'Launching payment portal...');
              await Future.delayed(const Duration(milliseconds: 300));
              DialogService.hideLoading();

              // Second tiny delay to insure dialog is gone from UI tree
              await Future.delayed(const Duration(milliseconds: 100));

              if (mounted) {
                debugPrint('[PesapalFlow] Pushing PesapalWebViewScreen...');
                final success = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PesapalWebViewScreen(
                      url: url,
                      orderTrackingId: result['order_tracking_id'],
                    ),
                  ),
                );
                debugPrint('[PesapalFlow] WebView returned success: $success');

                if (success == true && mounted) {
                  _showSuccessDialog(context, zone, session);
                }
              }
            } else {
              DialogService.hideLoading();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not get redirect URL')),
                );
              }
            }
          } else {
            DialogService.hideLoading();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['message'] ?? 'Payment initiation failed',
                  ),
                ),
              );
            }
          }
        } else {
          debugPrint('[PesapalFlow] Session was NULL');
          DialogService.hideLoading();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to prepare session. Please try again.'),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[PesapalFlow] Caught error: $e');
        DialogService.hideLoading();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showSuccessDialog(
    BuildContext context,
    Zone zone,
    ParkingSession? session,
  ) {
    DialogService.showSuccessDialog(
      title: 'Parking Started!',
      message: 'Your session in ${zone.name} is now active.',
      onDismiss: () {
        if (mounted) {
          // Close payment selection dialog if it's still on top
          Navigator.of(context).pop();

          if (session != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveSessionScreen(session: session),
              ),
            );
          }
        }
      },
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
                                  Consumer<SettingsProvider>(
                                    builder: (context, settings, _) => Text(
                                      'Rate: ${CurrencyFormatter.formatCurrency(zone.hourlyRate, settings.countryConfig)}/hr',
                                    ),
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
