import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:parking_user_app/features/auth/providers/vehicle_provider.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/parking/providers/parking_provider.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:parking_user_app/widgets/payment_selection_dialog.dart';
import 'package:parking_user_app/features/payments/services/payment_service.dart';
import 'package:parking_user_app/widgets/base_scaffold.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/payments/screens/pesapal_webview_screen.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';

class CreateReservationScreen extends StatefulWidget {
  final Zone? initialZone;
  const CreateReservationScreen({super.key, this.initialZone});

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  String? _selectedVehicleId;
  String? _selectedZoneId;
  DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _startTime = TimeOfDay.now();
  int _durationMinutes = 60;

  @override
  void initState() {
    super.initState();
    if (widget.initialZone != null) {
      _selectedZoneId = widget.initialZone!.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().fetchVehicles();
      context.read<ParkingProvider>().fetchZones();
    });
  }

  void _handleCreate() async {
    if (_selectedVehicleId == null || _selectedZoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle and a zone')),
      );
      return;
    }

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    if (startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be in the future')),
      );
      return;
    }

    final endDateTime = startDateTime.add(Duration(minutes: _durationMinutes));

    // Show confirmation modal
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (confirmDialogContext) => AlertDialog(
            title: const Text('Confirm Reservation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Do you want to book this parking spot?'),
                const SizedBox(height: 16),
                Text('Date: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                Text('Time: ${_startTime.format(confirmDialogContext)}'),
                Text('Duration: $_durationMinutes min'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmDialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(confirmDialogContext, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    // Show loading
    DialogService.showLoading(message: 'Creating reservation...');

    try {
      final reservation = await context
          .read<ReservationProvider>()
          .createReservation(
            vehicleId: _selectedVehicleId!,
            zoneId: _selectedZoneId!,
            startTime: startDateTime,
            endTime: endDateTime,
          );

      DialogService.hideLoading();

      if (reservation != null && mounted) {
        // Calculate cost
        final zone = context.read<ParkingProvider>().zones.firstWhere(
          (z) => z.id == _selectedZoneId,
        );
        final cost = zone.hourlyRate * (_durationMinutes / 60.0);
        final walletBalance =
            context.read<AuthProvider>().user?.walletBalance ?? 0.0;

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => PaymentSelectionDialog(
            amount: cost,
            walletBalance: walletBalance,
            onWalletSelected: () async {
              // Note: PaymentSelectionDialog already pops itself.
              if (!mounted) return;

              DialogService.showLoading(
                message: 'Processing wallet payment...',
              );

              try {
                final success = await context
                    .read<ReservationProvider>()
                    .confirmReservationWallet(reservation.id);

                DialogService.hideLoading();

                if (success && mounted) {
                  Navigator.pop(context); // Close CreateReservationScreen
                  DialogService.showSuccessDialog(
                    title: 'Reservation Confirmed!',
                    message:
                        'Your spot has been booked successfully using your wallet.',
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Wallet payment failed. Please check balance.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                DialogService.hideLoading();
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            onPesapalSelected: () async {
              // Note: PaymentSelectionDialog already pops itself.
              if (!mounted) return;

              DialogService.showLoading(message: 'Securing payment session...');

              try {
                final paymentService = PaymentService();
                final result = await paymentService.initiatePesapalPayment(
                  amount: cost,
                  description: "Reservation Payment: ${reservation.id}",
                  isWalletTopup: false,
                  reservationId: reservation.id,
                );

                DialogService.hideLoading();

                if (result['success'] == true && mounted) {
                  final url = result['redirect_url'];
                  if (url != null) {
                    final success = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (pushContext) => PesapalWebViewScreen(
                          url: url,
                          orderTrackingId: result['order_tracking_id'],
                        ),
                      ),
                    );

                    if (success == true && mounted) {
                      Navigator.pop(context); // Close CreateReservationScreen
                      DialogService.showSuccessDialog(
                        title: 'Reservation Confirmed!',
                        message: 'Your spot has been booked successfully.',
                      );
                    }
                  }
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Payment initiation failed',
                      ),
                    ),
                  );
                }
              } catch (e) {
                DialogService.hideLoading();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error initiating payment: $e')),
                  );
                }
              }
            },
          ),
        );
      }
    } catch (e) {
      DialogService.hideLoading();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating reservation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Book a Spot',
      showDrawer: true,
      currentIndex: -1, // Not a primary tab, but we want the drawer
      onTabChanged: (index) {
        final homeState = context.findAncestorStateOfType<HomeScreenState>();
        if (homeState != null) {
          homeState.navigateToTab(index);
          Navigator.pop(context); // Close this screen to go back to Home
        }
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle Selection
            const Text(
              'Select Vehicle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<VehicleProvider>(
              builder: (context, provider, _) {
                return DropdownButtonFormField<String>(
                  initialValue: _selectedVehicleId,
                  items: provider.vehicles
                      .map(
                        (v) => DropdownMenuItem(
                          value: v.id,
                          child: Text('${v.licensePlate} (${v.model})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedVehicleId = val),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Zone Selection
            const Text(
              'Select Zone',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<ParkingProvider>(
              builder: (context, provider, _) {
                return DropdownButtonFormField<String>(
                  initialValue: _selectedZoneId,
                  items: provider.zones
                      .map(
                        (z) =>
                            DropdownMenuItem(value: z.id, child: Text(z.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedZoneId = val),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Date Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 7),
                            ),
                          );
                          if (date != null) setState(() => _startDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(_startDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Time',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (time != null) setState(() => _startTime = time);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_startTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Duration
            const Text(
              'Duration (Minutes)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _durationMinutes > 15
                      ? () => setState(() => _durationMinutes -= 15)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_durationMinutes min',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed:
                      _durationMinutes <
                          720 // Max 12 hours
                      ? () => setState(() => _durationMinutes += 15)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _handleCreate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'CONFIRM BOOKING',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
