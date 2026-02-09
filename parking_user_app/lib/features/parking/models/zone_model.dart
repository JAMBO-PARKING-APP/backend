class Zone {
  final String id;
  final String name;
  final String code;
  final double latitude;
  final double longitude;
  final double hourlyRate;
  final int totalSlots;
  final int availableSlots;
  final String? description;

  Zone({
    required this.id,
    required this.name,
    required this.code,
    required this.latitude,
    required this.longitude,
    required this.hourlyRate,
    required this.totalSlots,
    required this.availableSlots,
    this.description,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      hourlyRate:
          double.tryParse(json['hourly_rate']?.toString() ?? '0') ?? 0.0,
      totalSlots: json['total_slots'] ?? 0,
      availableSlots: json['available_slots'] ?? 0,
      description: json['description'],
    );
  }
}
