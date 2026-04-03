class VehicleModel {
  final String id;
  final String licensePlate;
  final String make;
  final String model;
  final String color;
  final bool isActive;

  VehicleModel({
    required this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.color,
    required this.isActive,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id']?.toString() ?? '',
      licensePlate: (json['license_plate'] ?? json['licensePlate'] ?? '').toString(),
      make: (json['make'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      isActive: json['is_active'] == null ? true : (json['is_active'] as bool),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'license_plate': licensePlate,
      'make': make,
      'model': model,
      'color': color,
    };
  }
}

