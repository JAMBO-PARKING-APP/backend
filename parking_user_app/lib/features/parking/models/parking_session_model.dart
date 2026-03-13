import 'package:flutter/foundation.dart';

class ParkingSession {
  final String id;
  final String zoneName;
  final String vehiclePlate;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalCost;
  final String status;
  final String? qrCodeData;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final double hourlyRate;
  final String? slotCode;
  final String? slotType;
  final int durationMinutes;

  ParkingSession({
    required this.id,
    required this.zoneName,
    required this.vehiclePlate,
    required this.startTime,
    this.endTime,
    required this.totalCost,
    required this.status,
    this.hourlyRate = 1000.0,
    this.slotCode,
    this.slotType,
    this.durationMinutes = 0,
    this.qrCodeData,
    this.imagePath,
    this.latitude,
    this.longitude,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    try {
      return ParkingSession(
        id: json['id']?.toString() ?? '',
        zoneName: json['zone_name']?.toString() ?? 'Unknown Zone',
        vehiclePlate: json['vehicle_plate']?.toString() ?? 'Unknown Plate',
        startTime: json['start_time'] != null
            ? DateTime.parse(json['start_time']).toLocal()
            : DateTime.now(),
        endTime: json['planned_end_time'] != null
            ? DateTime.parse(json['planned_end_time']).toLocal()
            : null,
        totalCost:
            double.tryParse(
              (json['final_cost'] ?? json['estimated_cost'] ?? '0').toString(),
            ) ??
            0.0,
        status: json['status']?.toString() ?? 'unknown',
        hourlyRate:
            double.tryParse(json['hourly_rate']?.toString() ?? '1000') ?? 1000.0,
        slotCode: json['slot_code']?.toString(),
        slotType: json['slot_type']?.toString(),
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
        qrCodeData: json['qr_code_data']?.toString(),
        imagePath: json['image_path']?.toString(),
        latitude: double.tryParse(json['latitude']?.toString() ?? ''),
        longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      );
    } catch (e, stack) {
      debugPrint('ERROR parsing ParkingSession: $e');
      debugPrint('JSON data: $json');
      debugPrint(stack.toString());
      // Return a minimal session to avoid crashing the whole list/screen
      return ParkingSession(
        id: json['id']?.toString() ?? 'error',
        zoneName: 'Parsing Error',
        vehiclePlate: '',
        startTime: DateTime.now(),
        totalCost: 0.0,
        status: 'error',
      );
    }
  }
}
