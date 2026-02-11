class QRCodeScan {
  final String id;
  final String officerName;
  final String vehiclePlate;
  final String zoneName;
  final String scanStatus; // valid, invalid, expired, already_ended
  final bool sessionEnded;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  QRCodeScan({
    required this.id,
    required this.officerName,
    required this.vehiclePlate,
    required this.zoneName,
    required this.scanStatus,
    required this.sessionEnded,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory QRCodeScan.fromJson(Map<String, dynamic> json) {
    return QRCodeScan(
      id: json['id'],
      officerName: json['officer_name'] ?? '',
      vehiclePlate: json['vehicle_plate'] ?? '',
      zoneName: json['zone_name'] ?? '',
      scanStatus: json['scan_status'] ?? 'valid',
      sessionEnded: json['session_ended'] ?? false,
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
