class ParkingSession {
  final String id;
  final String vehiclePlate;
  final String? slotCode;
  final DateTime startTime;
  final int durationMinutes;
  final double amountDue;
  final String status;

  ParkingSession({
    required this.id,
    required this.vehiclePlate,
    this.slotCode,
    required this.startTime,
    required this.durationMinutes,
    required this.amountDue,
    required this.status,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    return ParkingSession(
      id: json['id'] ?? '',
      vehiclePlate: json['vehicle_plate'] ?? '',
      slotCode: json['slot_code'],
      startTime: DateTime.parse(json['start_time']),
      durationMinutes: json['duration_minutes'] ?? 0,
      amountDue: double.tryParse(json['amount_due']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'active',
    );
  }
}
