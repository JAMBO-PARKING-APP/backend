import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/features/payments/providers/payment_provider.dart';
import 'package:parking_user_app/features/payments/models/payment_method_model.dart';
import 'package:parking_user_app/features/payments/widgets/saved_cards_widget.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';

class PaymentSelectionDialog extends StatelessWidget {
  final double amount;
  final double walletBalance;
  final VoidCallback onWalletSelected;
  final Function(String paymentType) onPesapalSelected;
  final Function(PaymentMethod method)? onTokenSelected;

  const PaymentSelectionDialog({
    super.key,
    required this.amount,
    required this.walletBalance,
    required this.onWalletSelected,
    required this.onPesapalSelected,
    this.onTokenSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSufficientBalance = walletBalance >= amount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Amount
            Consumer<SettingsProvider>(
              builder: (context, settings, _) => Text(
                'Amount: ${CurrencyFormatter.formatCurrency(amount, settings.countryConfig)}',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),

            // Wallet Option
            InkWell(
              onTap: hasSufficientBalance
                  ? () {
                      Navigator.pop(context);
                      onWalletSelected();
                    }
                  : null,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hasSufficientBalance
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: hasSufficientBalance
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: hasSufficientBalance ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Wallet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Consumer<SettingsProvider>(
                            builder: (context, settings, _) => Text(
                              'Balance: ${CurrencyFormatter.formatCurrency(walletBalance, settings.countryConfig)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasSufficientBalance
                                    ? Colors.green.shade700
                                    : Colors.red,
                              ),
                            ),
                          ),
                          if (!hasSufficientBalance)
                            const Text(
                              'Insufficient balance',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                    if (hasSufficientBalance)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Saved Cards Section
            Consumer<PaymentProvider>(
              builder: (context, provider, _) {
                if (provider.paymentMethods.isEmpty) return const SizedBox.shrink();
                return SavedCardsWidget(
                  paymentMethods: provider.paymentMethods,
                  onCardSelected: (method) {
                    Navigator.pop(context);
                    if (onTokenSelected != null) {
                      onTokenSelected!(method);
                    }
                  },
                );
              },
            ),

            // Mobile Money / Card Option (if enabled)
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                // Check if any external payment method (like pesapal) is enabled
                final hasExternal = settings.countryConfig.paymentMethods.any(
                  (m) => m != 'wallet',
                );

                if (!hasExternal) return const SizedBox.shrink();

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    // Mobile Money Option
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onPesapalSelected('MOBILE_MONEY');
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_android,
                              color: Colors.blue,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mobile Money (UGX)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pay via MTN/Airtel',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Card Option (USD)
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onPesapalSelected('CARD');
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.purple, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.credit_card,
                              color: Colors.purple,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Card (USD)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pay \$${(amount / 3700).toStringAsFixed(2)} USD',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
