import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:parking_user_app/features/parking/providers/reservation_provider.dart';
import 'package:parking_user_app/features/parking/screens/create_reservation_screen.dart';
import 'package:parking_user_app/widgets/payment_selection_dialog.dart';
import 'package:parking_user_app/features/payments/services/payment_service.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<ReservationListScreen> createState() => _ReservationListScreenState();
}

class _ReservationListScreenState extends State<ReservationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().fetchReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateReservationScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No reservations yet',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateReservationScreen(),
                      ),
                    ),
                    child: const Text('Book a Spot'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.reservations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final res = provider.reservations[index];
              final status = res.status.toLowerCase();

              Color statusColor;
              String statusText;

              switch (status) {
                case 'active':
                case 'confirmed':
                  statusColor = Colors.green;
                  statusText = 'CONFIRMED';
                  break;
                case 'pending_payment':
                  statusColor = Colors.orange;
                  statusText = 'PAY NOW';
                  break;
                case 'expired':
                  statusColor = Colors.red;
                  statusText = 'EXPIRED';
                  break;
                case 'cancelled':
                  statusColor = Colors.grey;
                  statusText = 'CANCELLED';
                  break;
                case 'completed':
                  statusColor = Colors.blue;
                  statusText = 'COMPLETED';
                  break;
                default:
                  statusColor = Colors.grey;
                  statusText = status.toUpperCase();
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            res.zoneName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            res.vehiclePlate,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat('MMM dd, HH:mm').format(res.startTime)} - ${DateFormat('HH:mm').format(res.endTime)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      if (status == 'confirmed' ||
                          status == 'active' ||
                          status == 'pending_payment') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (status == 'pending_payment')
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _initiatePayment(context, res);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('PAY NOW'),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Cancel Reservation'),
                                      content: const Text(
                                        'Are you sure you want to cancel this reservation?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('NO'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('YES'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && mounted) {
                                    provider.cancelReservation(res.id);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('CANCEL'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _initiatePayment(BuildContext context, dynamic reservation) async {
    // Import necessary packages
    // We need Reservation model, but dynamic is used in loop.
    // Assuming reservation has 'cost' and 'id'.

    final authProvider = context.read<AuthProvider>();
    final walletBalance = authProvider.user?.walletBalance ?? 0.0;
    final cost = reservation.cost;

    showDialog(
      context: context,
      builder: (dialogContext) => PaymentSelectionDialog(
        amount: cost,
        walletBalance: walletBalance,
        onWalletSelected: () {
          Navigator.pop(dialogContext);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wallet payment for reservation coming soon'),
            ),
          );
        },
        onPesapalSelected: () async {
          Navigator.pop(dialogContext); // Close dialog

          // Show loading
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (c) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final paymentService = PaymentService();
            final result = await paymentService.initiatePesapalPayment(
              amount: cost,
              description: "Reservation Payment: ${reservation.id}",
              isWalletTopup: false,
              reservationId: reservation.id,
            );

            if (mounted) Navigator.pop(context);

            if (result['success'] == true && mounted) {
              final url = result['redirect_url'];
              if (url != null) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not launch payment URL'),
                      ),
                    );
                  }
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
            if (mounted) Navigator.pop(context); // Hide loading on error
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
}
