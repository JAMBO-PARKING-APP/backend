class Violation {
  final String id;
  final String vehiclePlate;
  final String zoneName;
  final String type;
  final double fineAmount;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime createdAt;

  Violation({
    required this.id,
    required this.vehiclePlate,
    required this.zoneName,
    required this.type,
    required this.fineAmount,
    required this.isPaid,
    this.paidAt,
    required this.createdAt,
  });

  factory Violation.fromJson(Map<String, dynamic> json) {
    return Violation(
      id: json['id'] ?? '',
      vehiclePlate: json['vehicle_plate'] ?? '',
      zoneName: json['zone_name'] ?? '',
      type: json['violation_type'] ?? '',
      fineAmount:
          double.tryParse(json['fine_amount']?.toString() ?? '0') ?? 0.0,
      isPaid: json['is_paid'] ?? false,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
