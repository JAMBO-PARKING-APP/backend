import 'package:flutter/material.dart';
import 'package:parking_officer_app/core/app_theme.dart';
import 'package:parking_officer_app/features/rewards/models/loyalty_models.dart';
import 'package:parking_officer_app/features/rewards/services/rewards_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _isLoading = false;
  String? _error;
  LoyaltyBalanceModel? _balance;
  List<LoyaltyPointTransactionModel> _history = [];

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
      final balance = await RewardsService().getBalance();
      final history = await RewardsService().getHistory();
      setState(() {
        _balance = balance;
        _history = history;
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
      appBar: AppBar(title: const Text('Rewards')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : _balance == null
                    ? const Text('No rewards available.',
                        style: TextStyle(color: AppTheme.textSecondary))
                    : ListView(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Loyalty Balance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _balance!.balance.toString(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tier: ${_balance!.tier}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Lifetime points: ${_balance!.lifetimePoints}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'History',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_history.isEmpty)
                            const Text('No reward transactions found.',
                                style: TextStyle(color: AppTheme.textSecondary))
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                final h = _history[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        h.transactionType.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Amount: ${h.amount}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        h.description.isEmpty ? '-' : h.description,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        h.createdAt,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
      ),
    );
  }
}

