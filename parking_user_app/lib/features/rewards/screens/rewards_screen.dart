import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parking_user_app/core/app_theme.dart';
import 'package:parking_user_app/features/rewards/providers/rewards_provider.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardsProvider>().fetchLoyaltyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Rewards')),
      body: Consumer<RewardsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchLoyaltyData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final account = provider.account;
          if (account == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () => provider.fetchLoyaltyData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Balance Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Available Points',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${account.balance}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${account.tier} Member',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (provider.transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No points history yet'),
                    ),
                  )
                else
                  ...provider.transactions.map(
                    (tx) => _buildTransactionItem(tx),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final isCredit = tx.isCredit;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          child: Icon(
            isCredit ? Icons.add : Icons.remove,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
        title: Text(tx.description),
        subtitle: Text(tx.createdAt),
        trailing: Text(
          '${isCredit ? '+' : '-'}${tx.amount}',
          style: TextStyle(
            color: isCredit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
