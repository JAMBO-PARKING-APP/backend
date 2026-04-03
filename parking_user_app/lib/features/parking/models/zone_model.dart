class Zone {
  final String id;
  final String name;
  final String code;
  final double latitude;
  final double longitude;
  final int totalSlots;
  final int availableSlots;
  final int occupiedSlots;
  final String? imageUrl;
  final String? googleMapsUrl;
  final double? distanceKm;

  Zone({
    required this.id,
    required this.name,
    required this.code,
    required this.latitude,
    required this.longitude,
    required this.totalSlots,
    required this.availableSlots,
    required this.occupiedSlots,
    this.imageUrl,
    this.googleMapsUrl,
    this.distanceKm,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    String? imageFrom(dynamic value) {
      final v = value?.toString();
      if (v == null || v.isEmpty || v == 'null') return null;
      return v;
    }

    return Zone(
      id: json['id'] ?? (json['zone_id'] ?? ''),
      name: json['name'] ?? (json['zone_name'] ?? ''),
      code: json['code'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      totalSlots: parseInt(json['total_slots'] ?? json['capacity']),
      availableSlots: parseInt(json['available_slots']),
      occupiedSlots: parseInt(json['occupied_slots']),
      imageUrl: imageFrom(json['zone_image']),
      googleMapsUrl: json['google_maps_url'],
      distanceKm: null,
    );
  }

  Zone copyWith({
    String? id,
    String? name,
    String? code,
    double? latitude,
    double? longitude,
    int? totalSlots,
    int? availableSlots,
    int? occupiedSlots,
    String? imageUrl,
    String? googleMapsUrl,
    double? distanceKm,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalSlots: totalSlots ?? this.totalSlots,
      availableSlots: availableSlots ?? this.availableSlots,
      occupiedSlots: occupiedSlots ?? this.occupiedSlots,
      imageUrl: imageUrl ?? this.imageUrl,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
