import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/features/payments/models/transaction_model.dart';
import 'package:parking_user_app/features/payments/providers/wallet_provider.dart';
import 'package:parking_user_app/features/payments/services/payments_service.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/payments/screens/payment_webview_screen.dart';
import 'package:parking_user_app/core/dialog_helper.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final PaymentsService _paymentsService = PaymentsService();
  PaymentSummaryModel? _summary;
  List<TransactionModel> _transactions = const [];
  List<InvoiceModel> _invoices = const [];
  List<PaymentMethodModel> _methods = const [];
  bool _loadingExtras = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await context.read<WalletProvider>().loadWallet();
    setState(() => _loadingExtras = true);
    try {
      final results = await Future.wait<dynamic>([
        _paymentsService.getSummary(),
        _paymentsService.getTransactions(),
        _paymentsService.getInvoices(),
        _paymentsService.getMethods(),
      ]);
      setState(() {
        _summary = results[0] as PaymentSummaryModel;
        _transactions = results[1] as List<TransactionModel>;
        _invoices = results[2] as List<InvoiceModel>;
        _methods = results[3] as List<PaymentMethodModel>;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingExtras = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final currencyFormat = NumberFormat.currency(
      symbol: '${wallet.currency} ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & payments')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primaryColor, AppTheme.primarySoft],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available balance', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Text(
                    currencyFormat.format(wallet.balance ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _topUpWallet,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: AppTheme.primaryDark,
                          ),
                          child: const Text('Top up wallet'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _refresh,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          child: const Text('Refresh'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _WalletMetric(
                    label: 'Paid',
                    value: currencyFormat.format(_summary?.totalPaid ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WalletMetric(
                    label: 'Pending',
                    value: currencyFormat.format(_summary?.pendingAmount ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _WalletMetric(
                    label: 'Violations due',
                    value: currencyFormat.format(_summary?.unpaidViolations ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WalletMetric(
                    label: 'Transactions',
                    value: '${_summary?.transactionCount ?? 0}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _WalletSection(
              title: 'Saved payment methods',
              loading: _loadingExtras,
              child: _methods.isEmpty
                  ? const Text('No saved methods yet.')
                  : Column(
                      children: _methods
                          .map((method) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.credit_card_rounded),
                                title: Text(method.label),
                                trailing: method.isDefault
                                    ? const Chip(label: Text('Default'))
                                    : null,
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 18),
            _WalletSection(
              title: 'Recent transactions',
              loading: _loadingExtras,
              child: _transactions.isEmpty
                  ? const Text('No transactions yet.')
                  : Column(
                      children: _transactions.take(5).map((transaction) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.receipt_long_rounded),
                          title: Text(transaction.status.toUpperCase()),
                          subtitle: Text(DateFormat('d MMM, HH:mm').format(transaction.createdAt)),
                          trailing: Text(transaction.amount.toString()),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 18),
            _WalletSection(
              title: 'Invoices',
              loading: _loadingExtras,
              child: _invoices.isEmpty
                  ? const Text('No invoices available yet.')
                  : Column(
                      children: _invoices.take(4).map((invoice) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.file_copy_outlined),
                          title: Text(invoice.invoiceNumber),
                          subtitle: Text(DateFormat('d MMM y').format(invoice.createdAt)),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _topUpWallet() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Top up wallet'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: 'Enter amount',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text.trim());
                if (amount == null || amount <= 0) return;
                final response = await _paymentsService.topUpWallet(amount);
                if (!mounted) return;
                Navigator.of(context).pop();
                if (response.redirectUrl != null) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PaymentWebviewScreen(url: response.redirectUrl!),
                    ),
                  );
                  _refresh();
                }
                if (response.success) {
                  DialogHelper.showSuccess(context, 'Payment Initiated', response.message ?? 'Top-up initiated.');
                } else {
                  DialogHelper.showError(context, 'Payment Failed', response.message ?? 'Failed to initiate top-up.');
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}

class _WalletMetric extends StatelessWidget {
  const _WalletMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _WalletSection extends StatelessWidget {
  const _WalletSection({
    required this.title,
    required this.loading,
    required this.child,
  });

  final String title;
  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ))
          else
            child,
        ],
      ),
    );
  }
}
