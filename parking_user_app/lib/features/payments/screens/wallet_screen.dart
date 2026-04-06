import 'package:flutter/material.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/core/user_strings.dart';
import 'package:parking_officer_app/features/payments/screens/topup_wallet_screen.dart';
import 'package:parking_officer_app/features/payments/screens/payment_methods_screen.dart';
import 'package:parking_officer_app/features/payments/screens/payment_summary_screen.dart';
import 'package:parking_officer_app/features/payments/screens/transactions_list_screen.dart';
import 'package:parking_officer_app/features/payments/screens/invoices_list_screen.dart';
import 'package:parking_officer_app/features/payments/screens/wallet_transactions_list_screen.dart';
import 'package:parking_officer_app/features/payments/providers/wallet_provider.dart';
import 'package:parking_officer_app/core/ui/space_ui.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  Future<void> _refresh() async {
    await context.read<WalletProvider>().fetchWallet();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(UserStrings.t(context, 'walletTitle'))),
      body: SpacePageBackground(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: kSpacePagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SpaceSectionTitle(
                  title: UserStrings.t(context, 'walletBalance'),
                  subtitle: UserStrings.t(context, 'walletBalanceHint'),
                ),
                if (wallet.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (wallet.error != null)
                  SpaceSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      wallet.error!,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  )
                else
                  SpaceSurfaceCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.currency,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${wallet.currencySymbol} ${wallet.balance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
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
                      await _refresh();
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
