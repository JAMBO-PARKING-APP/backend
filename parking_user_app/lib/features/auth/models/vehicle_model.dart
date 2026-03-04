class Vehicle {
  final String id;
  final String licensePlate;
  final String make;
  final String model;
  final String color;
  final bool isActive;

  Vehicle({
    required this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.color,
    required this.isActive,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  String get displayName => '$licensePlate ($make $model)';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'license_plate': licensePlate,
      'make': make,
      'model': model,
      'color': color,
      'is_active': isActive,
    };
  }
}
