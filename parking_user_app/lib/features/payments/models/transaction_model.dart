class Transaction {
  final String id;
  final String type;
  final double amount;
  final DateTime timestamp;
  final String status;
  final String description;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.status,
    required this.description,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      type: json['transaction_type'] ?? 'debit',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      timestamp: DateTime.parse(json['created_at']),
      status: json['status'] ?? 'completed',
      description: json['description'] ?? '',
    );
  }
}
