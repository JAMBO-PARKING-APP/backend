import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:parking_officer_app/features/parking/providers/non_app_user_session_provider.dart';
import 'package:parking_officer_app/features/parking/screens/create_guest_session_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NonAppUserSessionScreen extends StatelessWidget {
  const NonAppUserSessionScreen({super.key, this.zoneId, this.initialSession});

  final String? zoneId;
  final Map<String, dynamic>? initialSession;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = NonAppUserSessionProvider();
        if (initialSession != null) provider.restoreSession(initialSession!);
        return provider;
      },
      child: _NonAppUserSessionView(
        zoneId: zoneId,
        initialSession: initialSession,
      ),
    );
  }
}

class _NonAppUserSessionView extends StatefulWidget {
  const _NonAppUserSessionView({this.zoneId, this.initialSession});

  final String? zoneId;
  final Map<String, dynamic>? initialSession;

  @override
  State<_NonAppUserSessionView> createState() => _NonAppUserSessionViewState();
}

class _NonAppUserSessionViewState extends State<_NonAppUserSessionView> {
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.text =
        widget.initialSession?['driver_phone']?.toString() ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Parking Session')),
      body: Consumer<NonAppUserSessionProvider>(
        builder: (context, provider, _) {
          final session = provider.session;
          if (session == null) {
            return GuestSessionForm(
              initialZoneId: widget.zoneId,
              onSessionCreated: (createdSession) {
                _phoneController.text =
                    createdSession['driver_phone']?.toString() ?? '';
              },
            );
          }
          if (_phoneController.text.isEmpty) {
            _phoneController.text = session['driver_phone']?.toString() ?? '';
          }
          final amount =
              double.tryParse(
                session['estimated_cost']?.toString() ??
                    session['amount_due']?.toString() ??
                    '0',
              ) ??
              0;
          final isFree = amount <= 0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SessionSummary(session: session, amount: amount),
              if (provider.isPaymentConfirmed) ...[
                const SizedBox(height: 20),
                const _StatusBanner(
                  text: 'Payment confirmed. The guest session is active.',
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ] else ...[
                const SizedBox(height: 24),
                Text(
                  isFree ? 'Activate free session' : 'Payment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  isFree
                      ? 'Confirm to activate this free parking session.'
                      : 'Enter a phone number for the PesaPal checkout and complete payment before confirming.',
                ),
                if (!isFree) ...[
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('payment_phone'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Payment phone number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                  ),
                ],
                if (provider.paymentUrl != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Complete the payment below, then tap Verify payment.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 420,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _PaymentCheckout(url: provider.paymentUrl!),
                    ),
                  ),
                ],
                if (provider.error != null) ...[
                  const SizedBox(height: 12),
                  _StatusBanner(
                    text: provider.error!,
                    color: Colors.red,
                    icon: Icons.error_outline,
                  ),
                ],
                const SizedBox(height: 18),
                if (isFree)
                  _ActionButton(
                    key: const Key('confirm_guest_payment'),
                    label: 'Activate free session',
                    loading: provider.isConfirming,
                    onPressed: () => provider.confirmPayment(),
                  )
                else ...[
                  if (provider.paymentUrl == null)
                    _ActionButton(
                      key: const Key('start_guest_payment'),
                      label: 'Start payment',
                      loading: provider.isSubmitting,
                      onPressed: () {
                        if (_phoneController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a phone number for payment'),
                            ),
                          );
                          return;
                        }
                        provider.initiatePayment(_phoneController.text);
                      },
                    ),
                  if (provider.paymentUrl != null) ...[
                    const SizedBox(height: 10),
                    _ActionButton(
                      key: const Key('confirm_guest_payment'),
                      label: 'Verify payment',
                      loading: provider.isConfirming,
                      onPressed: () => provider.confirmPayment(),
                    ),
                  ],
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session, required this.amount});

  final Map<String, dynamic> session;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.tryParse(
      session['start_time']?.toString() ?? '',
    );
    final endTime = DateTime.tryParse(
      session['planned_end_time']?.toString() ?? '',
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 14),
            _DetailRow(label: 'License plate', value: _value('license_plate')),
            _DetailRow(label: 'Driver', value: _value('driver_name')),
            if (_value('driver_phone').isNotEmpty)
              _DetailRow(label: 'Phone', value: _value('driver_phone')),
            _DetailRow(label: 'Zone', value: _value('zone_name')),
            if (startTime != null)
              _DetailRow(
                label: 'Start',
                value: DateFormat.yMMMd().add_jm().format(startTime.toLocal()),
              ),
            if (endTime != null)
              _DetailRow(
                label: 'Ends',
                value: DateFormat.yMMMd().add_jm().format(endTime.toLocal()),
              ),
            const Divider(height: 24),
            _DetailRow(
              label: 'Amount due',
              value: 'UGX ${amount.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  String _value(String key) => session[key]?.toString() ?? '';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

class _PaymentCheckout extends StatefulWidget {
  const _PaymentCheckout({required this.url});

  final String url;

  @override
  State<_PaymentCheckout> createState() => _PaymentCheckoutState();
}

class _PaymentCheckoutState extends State<_PaymentCheckout> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onWebResourceError: (_) {}))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
