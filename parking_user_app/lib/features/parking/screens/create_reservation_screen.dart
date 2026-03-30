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
import 'package:parking_user_app/features/payments/providers/payment_provider.dart';
import 'package:parking_user_app/features/payments/screens/pesapal_webview_screen.dart';
import 'package:parking_user_app/core/localizations.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/parking/screens/active_session_screen.dart';
import 'package:parking_user_app/widgets/base_scaffold.dart';
import 'package:parking_user_app/features/home/screens/home_screen.dart';
import 'package:parking_user_app/widgets/time_knob.dart';

class CreateReservationScreen extends StatefulWidget {
  final Zone? initialZone;
  final bool isImmediate;
  const CreateReservationScreen({super.key, this.initialZone, this.isImmediate = false});

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

  AppLocalizations get l10n => AppLocalizations.of(context);


  @override
  void initState() {
    super.initState();
    if (widget.initialZone != null) {
      _selectedZoneId = widget.initialZone!.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().fetchVehicles();
      context.read<ParkingProvider>().fetchZones();
      context.read<PaymentProvider>().fetchWalletData();
    });
  }

  void _handleCreate() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (_selectedVehicleId == null || _selectedZoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectVehicleAndZone)),
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

    if (!widget.isImmediate && startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.startTimeInFuture)),
      );
      return;
    }

    final endDateTime = startDateTime.add(Duration(minutes: _durationMinutes));

    // Show confirmation modal
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (confirmDialogContext) => AlertDialog(
            title: Text(l10n.confirmReservation),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.isImmediate 
                    ? l10n.startReservedSessionPrompt
                    : l10n.bookSpotPrompt),
                const SizedBox(height: 16),
                if (!widget.isImmediate) ...[
                  Text('${l10n.date}: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                  Text('${l10n.time}: ${_startTime.format(confirmDialogContext)}'),
                ],
                Text('${l10n.duration}: $_durationMinutes ${l10n.minutes}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmDialogContext, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(confirmDialogContext, true),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    // Calculate cost
    final zone = context.read<ParkingProvider>().zones.firstWhere(
      (z) => z.id == _selectedZoneId,
      orElse: () => throw Exception('Selected zone not found'),
    );
    final cost = zone.hourlyRate * (_durationMinutes / 60.0);
    final walletBalance =
        context.read<AuthProvider>().user?.walletBalance ?? 0.0;

    // Show Payment Selection Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (paymentDialogContext) => PaymentSelectionDialog(
        amount: cost,
        walletBalance: walletBalance,
        onWalletSelected: () async {
          if (!mounted) return;
          DialogService.showLoading(
            message: widget.isImmediate ? l10n.sessionStarting : l10n.processingReservation,
          );

          try {
            if (widget.isImmediate) {
              final session = await context.read<ParkingProvider>().startParking(
                context: context,
                vehicleId: _selectedVehicleId!,
                zoneId: _selectedZoneId!,
                durationHours: _durationMinutes / 60.0,
                paymentMethod: 'wallet',
              );
              DialogService.hideLoading();
              if (session != null && mounted) {
                context.read<PaymentProvider>().fetchWalletData(); // Refresh balance
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => ActiveSessionScreen(session: session)),
                );
              }
            } else {
              final reservation = await context
                  .read<ReservationProvider>()
                  .createReservation(
                    vehicleId: _selectedVehicleId!,
                    zoneId: _selectedZoneId!,
                    startTime: startDateTime,
                    endTime: endDateTime,
                    confirmImmediately: true,
                    paymentMethod: 'wallet',
                  );

              DialogService.hideLoading();

              if (reservation != null && mounted) {
                context.read<PaymentProvider>().fetchWalletData(); // Refresh balance
                _showSuccessWithStartSession(reservation);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.reservationFailed),
                  ),
                );
              }
            }
          } catch (e) {
            DialogService.hideLoading();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        onPesapalSelected: (paymentType) async {
          if (!mounted) return;
          DialogService.showLoading(message: l10n.initiatingPayment);

          try {
            if (widget.isImmediate) {
               // Direct session start with Pesapal
               final paymentService = PaymentService();
              final result = await paymentService.initiatePesapalPayment(
                amount: cost,
                description: "Parking Session: ${zone.name}",
                isWalletTopup: false,
                paymentType: paymentType,
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
                    context.read<PaymentProvider>().fetchWalletData(); // Refresh balance
                    DialogService.showSuccessDialog(
                      title: l10n.paymentSuccessful,
                      message: '${AppLocalizations.of(context).sessionStarting} in ${zone.name}.',
                      onDismiss: () {
                        // For immediate sessions, we assume the backend starts it
                        // after payment. The user might need to check ActiveSessionScreen.
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        );
                      },
                    );
                  }
                }
              }
            } else {
              // Create reservation first (as pending_payment) to get the ID for Pesapal
              final reservation = await context
                  .read<ReservationProvider>()
                  .createReservation(
                    vehicleId: _selectedVehicleId!,
                    zoneId: _selectedZoneId!,
                    startTime: startDateTime,
                    endTime: endDateTime,
                    confirmImmediately: false,
                    paymentMethod: 'pesapal',
                  );

              if (reservation == null) {
                DialogService.hideLoading();
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Failed to initialize reservation')));
                }
                return;
              }

              final paymentService = PaymentService();
              final result = await paymentService.initiatePesapalPayment(
                amount: cost,
                description: "Reservation Payment: ${reservation.id}",
                isWalletTopup: false,
                reservationId: reservation.id,
                paymentType: paymentType,
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
                    _showSuccessWithStartSession(reservation);
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
        onTokenSelected: (method) async {
          if (!mounted) return;
          DialogService.showLoading(message: l10n.processingPayment);

          try {
            final paymentService = PaymentService();
            final result = await paymentService.executePesapalTokenPayment(
              amount: cost,
              paymentMethodId: method.id,
              description: widget.isImmediate ? "Parking Session: ${zone.name}" : "Reservation Payment",
            );

            DialogService.hideLoading();

            if (result['success'] == true && mounted) {
              final url = result['redirect_url'];
              if (url != null && url.isNotEmpty) {
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
                    DialogService.showSuccessDialog(
                      title: l10n.paymentSuccessful,
                      message: widget.isImmediate 
                          ? l10n.sessionStarting 
                          : l10n.spotBooked,
                      onDismiss: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                      },
                    );
                  }
              } else {
                 DialogService.showSuccessDialog(
                    title: 'One-Click Success!',
                    message: widget.isImmediate 
                        ? 'Your parking session is starting now.' 
                        : 'Your spot has been booked.',
                    onDismiss: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    },
                 );
              }
            } else if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'Token payment failed')),
               );
            }
          } catch (e) {
            DialogService.hideLoading();
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showSuccessWithStartSession(dynamic reservation) {
    if (!mounted) return;

    // Check if user can start session now (e.g. within 15 mins of start time)
    final now = DateTime.now();
    final startTime = reservation.startTime is String 
        ? DateTime.parse(reservation.startTime) 
        : reservation.startTime as DateTime;
    
    final bool canStartNow = startTime.difference(now).inMinutes <= 15;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.reservationConfirmed),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.spotBookedSuccess),
            if (canStartNow) ...[
              const SizedBox(height: 16),
              Text(
                l10n.canStartNowPrompt,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(this.context); // Close CreateReservationScreen
            },
            child: Text(l10n.ok),
          ),
          if (canStartNow)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                DialogService.showLoading(message: l10n.sessionStarting);
                try {
                  final parkingProvider = this.context.read<ParkingProvider>();
                  final session = await parkingProvider.startParking(
                    context: this.context,
                    vehicleId: _selectedVehicleId!,
                    zoneId: _selectedZoneId!,
                    durationHours: _durationMinutes / 60.0,
                    paymentMethod: 'wallet',
                  );
                  DialogService.hideLoading();

                  if (!mounted) return;

                  if (session != null) {
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActiveSessionScreen(session: session),
                        ),
                      );
                    }
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to start session. Please try from Home.')),
                    );
                  }
                } catch (e) {
                  DialogService.hideLoading();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error starting session: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: Text(l10n.startParkingNow.toUpperCase()),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BaseScaffold(
      title: widget.isImmediate ? l10n.startParking : l10n.bookSpot,
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
            Text(
              l10n.selectVehicle,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
            Text(
              l10n.selectZone,
              style: const TextStyle(fontWeight: FontWeight.bold),
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

            if (!widget.isImmediate) ...[
              // Date Selection
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.date,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                        Text(
                          'Start Time',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
            ],

            // Time Knob
            const SizedBox(height: 16),
            Center(
              child: TimeKnob(
                initialMinutes: _durationMinutes,
                onChanged: (val) => setState(() => _durationMinutes = val),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _handleCreate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.isImmediate ? l10n.startParkingNow : l10n.confirmBooking,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
