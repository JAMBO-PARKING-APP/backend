class Zone {
  final String id;
  final String name;
  final String code;
  final double latitude;
  final double longitude;
  final int totalSlots;
  final int availableSlots;
  final int occupiedSlots;

  Zone({
    required this.id,
    required this.name,
    required this.code,
    required this.latitude,
    required this.longitude,
    required this.totalSlots,
    required this.availableSlots,
    required this.occupiedSlots,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] ?? (json['zone_id'] ?? ''),
      name: json['name'] ?? (json['zone_name'] ?? ''),
      code: json['code'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      totalSlots: json['total_slots'] ?? 0,
      availableSlots: json['available_slots'] ?? 0,
      occupiedSlots: json['occupied_slots'] ?? 0,
    );
  }
}
