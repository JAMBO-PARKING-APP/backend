class ReservationModel {
  final String id;
  final String vehiclePlate;
  final String zoneName;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final double cost;
  final String? paymentReference;
  final DateTime createdAt;

  ReservationModel({
    required this.id,
    required this.vehiclePlate,
    required this.zoneName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.cost,
    this.paymentReference,
    required this.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id']?.toString() ?? '',
      vehiclePlate: (json['vehicle_plate'] ?? json['vehicle']?['license_plate'] ?? '').toString(),
      zoneName: (json['zone_name'] ?? json['zone']?['name'] ?? '').toString(),
      startTime: DateTime.parse((json['start_time'] ?? json['reserved_from']).toString()),
      endTime: DateTime.parse((json['end_time'] ?? json['reserved_until']).toString()),
      status: json['status']?.toString() ?? 'pending_payment',
      cost: double.tryParse((json['cost'] ?? 0).toString()) ?? 0.0,
      paymentReference: json['payment_reference']?.toString(),
      createdAt: DateTime.parse((json['created_at'] ?? json['createdAt']).toString()),
    );
  }

  bool get canCancel => status != 'cancelled' && status != 'expired' && status != 'completed';
  bool get isPendingPayment => status == 'pending_payment';
}

