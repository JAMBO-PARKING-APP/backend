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
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/payments/screens/pesapal_webview_screen.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/widgets/base_scaffold.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';

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
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final now = TimeOfDay.now();
          final startMinutes = now.hour * 60 + now.minute;
          final endMinutes = endTime.hour * 60 + endTime.minute;

          int durationMinutes = endMinutes - startMinutes;
          if (durationMinutes <= 0) durationMinutes += 24 * 60; // Next day

          final durationHours = durationMinutes / 60.0;
          final isDurationValid = durationHours >= 0.25;
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
                            setDialogState(() => selectedVehicle = val),
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
                      setDialogState(() => endTime = time);
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
                          endTime.format(dialogContext),
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
                  style: TextStyle(
                    color: isDurationValid ? Colors.grey.shade600 : Colors.red,
                  ),
                ),
                if (!isDurationValid)
                  const Text(
                    'Minimum duration is 15 minutes (0.25 hrs)',
                    style: TextStyle(color: Colors.red, fontSize: 12),
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
                onPressed: (selectedVehicle == null || !isDurationValid)
                    ? null
                    : () {
                        Navigator.pop(
                          dialogContext,
                        ); // Close StartParking dialog

                        // Show payment selection dialog
                        final walletBalance =
                            context.read<AuthProvider>().user?.walletBalance ??
                            0.0;

                        showDialog(
                          context: context,
                          builder: (paymentDialogContext) => PaymentSelectionDialog(
                            amount: estimatedCost,
                            walletBalance: walletBalance,
                            onWalletSelected: () async {
                              // Navigator.pop(paymentDialogContext) is NOT needed here
                              // because PaymentSelectionDialog already pops itself.
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
                              // Navigator.pop(paymentDialogContext) is NOT needed here
                              // because PaymentSelectionDialog already pops itself.
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
          builder: (confirmDialogContext) => AlertDialog(
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
                  builder: (confirmDialogContext, settings, _) =>
                      _buildConfirmRow(
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
                onPressed: () => Navigator.pop(confirmDialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(confirmDialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(confirmDialogContext).primaryColor,
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
                    builder: (pushContext) => PesapalWebViewScreen(
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
        // Navigation is now handled automatically by HomeScreen's listener
        // which detects the newlyStartedSession in ParkingProvider.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Parking Zones',
      showDrawer: true,
      currentIndex: 1, // Zones index
      onTabChanged: (index) {
        // If it's a child of HomeScreen, it should notify parent
        // For simplicity, we can use a key or find the state
        final homeState = context.findAncestorStateOfType<HomeScreenState>();
        if (homeState != null) {
          homeState.navigateToTab(index);
        }
      },
      body: Consumer<ZoneProvider>(
        builder: (context, zoneProvider, _) {
          if (zoneProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final zones = zoneProvider.zones;
          if (zones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_filled_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No parking zones found nearby',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => zoneProvider.fetchZones(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: zones.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final zone = zones[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                child: InkWell(
                  onTap: () => _showStartParkingDialog(context, zone),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
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
                                    builder: (context, settings, _) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Rate: ${CurrencyFormatter.formatCurrency(zone.hourlyRate, settings.countryConfig)}/hr',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.local_parking_rounded, size: 16, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${zone.code} • ${zone.availableSlots}/${zone.totalSlots} slots',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (zone.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    zone.imageUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.directions_car_filled_rounded,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (pushContext) =>
                                        ParkingMapScreen(initialZone: zone),
                                  ),
                                );
                              },
                              tooltip: 'View on Map',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  _launchMaps(zone.latitude, zone.longitude),
                              icon: const Icon(Icons.directions_outlined, size: 20),
                              label: const Text('Get Directions'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _showStartParkingDialog(context, zone),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                minimumSize: const Size(120, 40),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('Book Now'),
                            ),
                          ],
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
