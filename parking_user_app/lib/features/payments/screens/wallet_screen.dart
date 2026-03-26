import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:parking_user_app/features/payments/providers/payment_provider.dart';
import 'package:parking_user_app/features/payments/screens/pesapal_webview_screen.dart';
import 'package:parking_user_app/features/payments/screens/transaction_history_screen.dart';
import 'package:parking_user_app/core/dialog_service.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/widgets/glass_container.dart';
import 'package:parking_user_app/features/payments/models/payment_method_model.dart';
import 'package:parking_user_app/widgets/payment_selection_dialog.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().fetchWalletData();
    });
  }

  void _handleTopUp() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final balance = context.read<PaymentProvider>().balance;

    showDialog(
      context: context,
      builder: (context) => PaymentSelectionDialog(
        amount: amount,
        walletBalance: balance,
        onWalletSelected: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot top up wallet using wallet!')),
          );
        },
        onPesapalSelected: (paymentType) async {
          _executeTopUp(amount, paymentType);
        },
        onTokenSelected: (method) async {
          _executeTokenTopUp(amount, method);
        },
      ),
    );
  }

  void _executeTokenTopUp(double amount, dynamic method) async {
     showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await context.read<PaymentProvider>().executePesapalTokenPayment(
            amount: amount,
            paymentMethodId: method.id,
            description: 'Wallet Top-up (One-click)',
          );

      if (mounted) Navigator.pop(context);

      if (result['success'] && mounted) {
        final url = result['redirect_url'];
        if (url != null && url.isNotEmpty) {
           final success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PesapalWebViewScreen(
                url: url,
                orderTrackingId: result['order_tracking_id'],
              ),
            ),
          );
          if (success == true && mounted) {
             context.read<PaymentProvider>().fetchWalletData();
             DialogService.showSuccessDialog(
              title: 'Top-up Successful!',
              message: 'Your wallet has been credited.',
            );
            _amountController.clear();
          }
        } else {
          context.read<PaymentProvider>().fetchWalletData();
          DialogService.showSuccessDialog(
            title: 'Top-up Successful!',
            message: 'Your wallet has been credited via one-click payment.',
          );
          _amountController.clear();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Token payment failed'),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _executeTopUp(double amount, String paymentType) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await context.read<PaymentProvider>().initiatePesapalPayment(
            amount: amount,
            description: 'Wallet Top-up',
            paymentType: paymentType,
          );

      if (mounted) Navigator.pop(context);

      if (result['success'] && mounted) {
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PesapalWebViewScreen(
              url: result['redirect_url'],
              orderTrackingId: result['order_tracking_id'],
            ),
          ),
        );

        if (success == true && mounted) {
          context.read<PaymentProvider>().fetchWalletData();
          DialogService.showSuccessDialog(
            title: 'Top-up Successful!',
            message: 'Your wallet has been credited.',
          );
          _amountController.clear();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to initiate payment'),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error initiating top-up: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchWalletData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Balance Card
                  GlassContainer(
                    padding: const EdgeInsets.all(32),
                    gradientColors: [
                      AppTheme.primaryColor,
                      const Color(0xFF38A169),
                    ],
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Available Balance',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Consumer<SettingsProvider>(
                          builder: (context, settings, _) => Text(
                            CurrencyFormatter.formatCurrency(
                              provider.balance,
                              settings.countryConfig,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Space Park Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Top-up Section
                  const Text(
                    'Quick Top-up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.grey.shade300),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: Center(
                          widthFactor: 1,
                          child: Consumer<SettingsProvider>(
                            builder: (context, settings, _) => Text(
                              settings.countryConfig.currencySymbol,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [1000, 5000, 10000, 20000, 50000]
                          .map(
                            (amt) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  amt.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () =>
                                    _amountController.text = amt.toString(),
                                backgroundColor: Colors.white,
                                elevation: 0,
                                side: BorderSide(color: Colors.grey.shade200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleTopUp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'TOP UP NOW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TransactionHistoryScreen(),
                          ),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (provider.transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ...provider.transactions.take(5).map((tx) {
                      final isCredit =
                          tx.type == 'credit' || tx.type == 'topup';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade50),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  (isCredit
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor)
                                      .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCredit
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isCredit
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            tx.description,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM dd, HH:mm').format(tx.timestamp),
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Consumer<SettingsProvider>(
                            builder: (context, settings, _) => Text(
                              '${isCredit ? "+" : "-"} ${CurrencyFormatter.formatCurrency(tx.amount, settings.countryConfig)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isCredit
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
