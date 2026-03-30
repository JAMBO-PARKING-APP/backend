import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:parking_user_app/features/payments/providers/payment_provider.dart';
import 'package:parking_user_app/features/payments/models/payment_method_model.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/core/utils/currency_formatter.dart';

class PaymentSelectionDialog extends StatelessWidget {
  final double amount;
  final double walletBalance;
  final VoidCallback onWalletSelected;
  final Function(String paymentType) onPesapalSelected;
  final Function(dynamic method)? onTokenSelected;

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Amount: ${CurrencyFormatter.formatCurrency(amount, settings.countryConfig)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Payment Options
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wallet Option
                  _PaymentOption(
                    title: 'My Wallet',
                    subtitle:
                        'Balance: ${CurrencyFormatter.formatCurrency(walletBalance, Provider.of<SettingsProvider>(context).countryConfig)}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: Colors.green,
                    isEnabled: hasSufficientBalance,
                    isSelected: false,
                    onTap: hasSufficientBalance
                        ? () {
                            Navigator.pop(context);
                            onWalletSelected();
                          }
                        : null,
                    warningText: !hasSufficientBalance ? 'Insufficient balance' : null,
                  ),

                  const SizedBox(height: 16),

                  // Mobile Money Option
                  _PaymentOption(
                    title: 'Mobile Money',
                    subtitle: 'MTN/Airtel UGX',
                    icon: Icons.phone_android_rounded,
                    iconColor: AppTheme.primaryColor,
                    isEnabled: true,
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      onPesapalSelected('MOBILE_MONEY');
                    },
                  ),

                  const SizedBox(height: 16),

                  // Card Option
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) => _PaymentOption(
                      title: 'Debit/Credit Card',
                      subtitle:
                          'Pay \$${(amount / 3700).toStringAsFixed(2)} USD',
                      icon: Icons.credit_card_rounded,
                      iconColor: Colors.purple,
                      isEnabled: true,
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        onPesapalSelected('CARD');
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Footer with Cancel Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: AppTheme.borderColor,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isEnabled;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? warningText;

  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isEnabled,
    required this.isSelected,
    required this.onTap,
    this.warningText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isEnabled
                ? iconColor.withValues(alpha: 0.08)
                : Colors.grey.shade100,
            border: Border.all(
              color: isEnabled
                  ? iconColor.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? iconColor.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? iconColor : Colors.grey.shade400,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isEnabled
                            ? AppTheme.textPrimary
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isEnabled
                            ? AppTheme.textSecondary
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (warningText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        warningText!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isEnabled && isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: iconColor,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
