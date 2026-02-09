class ParkingSession {
  final String id;
  final String zoneName;
  final String vehiclePlate;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalCost;
  final String status;

  ParkingSession({
    required this.id,
    required this.zoneName,
    required this.vehiclePlate,
    required this.startTime,
    this.endTime,
    required this.totalCost,
    required this.status,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    return ParkingSession(
      id: json['id'] ?? '',
      zoneName: json['zone_name'] ?? '',
      vehiclePlate: json['vehicle_plate'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      totalCost:
          double.tryParse(
            (json['final_cost'] ?? json['estimated_cost'])?.toString() ?? '0',
          ) ??
          0.0,
      status: json['status'] ?? '',
    );
  }
}
