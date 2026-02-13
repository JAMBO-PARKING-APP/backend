class LoyaltyAccount {
  final int balance;
  final int lifetimePoints;
  final String tier;

  LoyaltyAccount({
    required this.balance,
    required this.lifetimePoints,
    required this.tier,
  });

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccount(
      balance: json['balance'] ?? 0,
      lifetimePoints: json['lifetime_points'] ?? 0,
      tier: json['tier'] ?? 'Bronze',
    );
  }
}

class PointTransaction {
  final int amount;
  final String transactionType;
  final String description;
  final String? referenceId;
  final String createdAt;

  PointTransaction({
    required this.amount,
    required this.transactionType,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      amount: json['amount'] ?? 0,
      transactionType: json['transaction_type'] ?? 'unknown',
      description: json['description'] ?? '',
      referenceId: json['reference_id'],
      createdAt: json['created_at'] ?? '',
    );
  }

  bool get isCredit => ['earned', 'bonus'].contains(transactionType);
}
