class TransactionModel {
  final String id;
  final num amount;
  final String status;
  final DateTime createdAt;

  final String? paymentMethodDisplay;
  final String? pesapalOrderTrackingId;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paymentMethodDisplay,
    this.pesapalOrderTrackingId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    final amount = amountRaw is num
        ? amountRaw
        : num.tryParse(amountRaw?.toString() ?? '') ?? 0;
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      amount: amount,
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      paymentMethodDisplay: json['payment_method_display']?.toString(),
      pesapalOrderTrackingId: json['pesapal_order_tracking_id']?.toString(),
    );
  }
}

