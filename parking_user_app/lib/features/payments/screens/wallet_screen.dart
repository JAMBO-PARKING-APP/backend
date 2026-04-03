import 'package:flutter/material.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/core/user_strings.dart';
import 'package:parking_officer_app/features/payments/services/wallet_service.dart';
import 'package:parking_officer_app/features/payments/screens/topup_wallet_screen.dart';
import 'package:parking_officer_app/features/payments/screens/payment_methods_screen.dart';
import 'package:parking_officer_app/features/payments/screens/payment_summary_screen.dart';
import 'package:parking_officer_app/features/payments/screens/transactions_list_screen.dart';
import 'package:parking_officer_app/features/payments/screens/invoices_list_screen.dart';
import 'package:parking_officer_app/features/payments/screens/wallet_transactions_list_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = false;
  String? _error;
  double? _balance;
  String _currency = 'UGX';
  String _currencySymbol = 'UGX';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await WalletService().getWalletBalance();
      setState(() {
        _balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        _currency = data['currency']?.toString() ?? 'UGX';
        _currencySymbol = data['currency_symbol']?.toString() ?? 'UGX';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(UserStrings.t(context, 'walletTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              UserStrings.t(context, 'walletBalance'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  '${_currencySymbol} ${_balance?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TopupWalletScreen(),
                    ),
                  );
                  await _load();
                },
                icon: const Icon(Icons.add_card_rounded),
                label: Text(UserStrings.t(context, 'topUpWallet')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _actionTile(
              icon: Icons.payment_rounded,
              title: UserStrings.t(context, 'paymentMethods'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentMethodsScreen(),
                ),
              ),
            ),
            _actionTile(
              icon: Icons.summarize_rounded,
              title: UserStrings.t(context, 'paymentSummary'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaymentSummaryScreen(),
                ),
              ),
            ),
            _actionTile(
              icon: Icons.receipt_long_rounded,
              title: UserStrings.t(context, 'invoices'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InvoicesListScreen(),
                ),
              ),
            ),
            _actionTile(
              icon: Icons.history_rounded,
              title: UserStrings.t(context, 'transactions'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionsListScreen(),
                ),
              ),
            ),
            _actionTile(
              icon: Icons.account_balance_wallet_rounded,
              title: UserStrings.t(context, 'walletTransactions'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WalletTransactionsListScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

