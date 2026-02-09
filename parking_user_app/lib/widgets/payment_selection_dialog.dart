import 'package:flutter/material.dart';

class PaymentSelectionDialog extends StatelessWidget {
  final double amount;
  final double walletBalance;
  final VoidCallback onWalletSelected;
  final VoidCallback onPesapalSelected;

  const PaymentSelectionDialog({
    super.key,
    required this.amount,
    required this.walletBalance,
    required this.onWalletSelected,
    required this.onPesapalSelected,
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
            Text(
              'Amount: UGX ${amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
                          Text(
                            'Balance: UGX ${walletBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasSufficientBalance
                                  ? Colors.green.shade700
                                  : Colors.red,
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

            // Pesapal Option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onPesapalSelected();
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
                    Icon(Icons.credit_card, color: Colors.blue, size: 32),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pesapal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pay with Mobile Money or Card',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                  ],
                ),
              ),
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
