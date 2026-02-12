class ParkingSession {
  final String id;
  final String vehiclePlate;
  final String? slotCode;
  final String? slotNumber;
  final DateTime startTime;
  final DateTime plannedEndTime;
  final int durationMinutes;
  final double amountDue;
  final String status;
  final String? driverName;
  final String? driverPhone;

  ParkingSession({
    required this.id,
    required this.vehiclePlate,
    this.slotCode,
    this.slotNumber,
    required this.startTime,
    required this.plannedEndTime,
    required this.durationMinutes,
    required this.amountDue,
    required this.status,
    this.driverName,
    this.driverPhone,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    return ParkingSession(
      id: json['id'] ?? '',
      vehiclePlate:
          json['vehicle_plate'] ?? json['vehicle']?['license_plate'] ?? '',
      slotCode: json['slot_code'] ?? json['parking_slot']?['code'],
      slotNumber: json['slot_number'] ?? json['parking_slot']?['slot_number'],
      startTime: DateTime.parse(json['start_time']),
      plannedEndTime: DateTime.parse(json['planned_end_time']),
      durationMinutes: json['duration_minutes'] ?? 0,
      amountDue:
          double.tryParse(
            json['amount_due']?.toString() ??
                json['estimated_cost']?.toString() ??
                '0',
          ) ??
          0.0,
      status: json['status'] ?? 'active',
      driverName:
          json['driver_name'] ?? json['vehicle']?['owner']?['full_name'],
      driverPhone: json['driver_phone'] ?? json['vehicle']?['owner']?['phone'],
    );
  }
}
