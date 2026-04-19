import 'package:flutter/material.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/features/rewards/services/rewards_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardsService _service = RewardsService();
  LoyaltyBalanceModel? _balance;
  List<LoyaltyPointTransactionModel> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final balance = await _service.getBalance();
      final history = await _service.getHistory();
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _history = history;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accentColor, AppTheme.accentSoft, AppTheme.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Loyalty balance', style: TextStyle(color: AppTheme.primaryDark)),
                        const SizedBox(height: 10),
                        Text(
                          '${_balance?.balance ?? 0} pts',
                          style: const TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Tier: ${_balance?.tier ?? 'Bronze'}'),
                        Text('Lifetime points: ${_balance?.lifetimePoints ?? 0}'),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Points history', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_history.isEmpty)
                    const Text('No reward activity yet.')
                  else
                    ..._history.take(8).map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: item.amount >= 0
                                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                                : AppTheme.errorColor.withValues(alpha: 0.12),
                            child: Icon(
                              item.amount >= 0 ? Icons.add_rounded : Icons.remove_rounded,
                              color: item.amount >= 0 ? AppTheme.primaryColor : AppTheme.errorColor,
                            ),
                          ),
                          title: Text(item.transactionType),
                          subtitle: Text(item.description.isEmpty ? 'Rewards activity' : item.description),
                          trailing: Text('${item.amount > 0 ? '+' : ''}${item.amount}'),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
