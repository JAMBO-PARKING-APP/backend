class Reservation {
  final String id;
  final String vehiclePlate;
  final String zoneName;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final double cost;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.vehiclePlate,
    required this.zoneName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.cost,
    required this.createdAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] ?? '',
      vehiclePlate: json['vehicle_plate'] ?? '',
      zoneName: json['zone_name'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'] ?? '',
      cost: double.tryParse(json['cost']?.toString() ?? '0') ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
