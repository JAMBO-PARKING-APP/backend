import 'package:parking_officer_app/core/api_client.dart';

class VehicleSearchModel {
  final String id;
  final String licensePlate;
  final String make;
  final String model;
  final String color;
  final String ownerName;
  final String ownerPhone;
  final ActiveSessionData? activeSession;
  final int unpaidViolations;
  final String status;
  final int overdueDurationMinutes;
  final double suggestedFine;

  VehicleSearchModel({
    required this.id,
    required this.licensePlate,
    required this.make,
    required this.model,
    required this.color,
    required this.ownerName,
    required this.ownerPhone,
    this.activeSession,
    required this.unpaidViolations,
    required this.status,
    this.overdueDurationMinutes = 0,
    this.suggestedFine = 0.0,
  });

  factory VehicleSearchModel.fromJson(Map<String, dynamic> json) {
    return VehicleSearchModel(
      id: json['id'],
      licensePlate: json['license_plate'],
      make: json['make'],
      model: json['model'],
      color: json['color'],
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      activeSession: json['active_session'] != null
          ? ActiveSessionData.fromJson(json['active_session'])
          : null,
      unpaidViolations: json['unpaid_violations'] ?? 0,
      status: json['status'] ?? 'unknown',
      overdueDurationMinutes: json['overdue_duration_minutes'] ?? 0,
      suggestedFine: (json['suggested_fine'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ActiveSessionData {
  final String id;
  final String zone;
  final DateTime startedAt;
  final DateTime plannedEnd;
  final double amountDue;

  ActiveSessionData({
    required this.id,
    required this.zone,
    required this.startedAt,
    required this.plannedEnd,
    required this.amountDue,
  });

  factory ActiveSessionData.fromJson(Map<String, dynamic> json) {
    return ActiveSessionData(
      id: json['id'],
      zone: json['zone'],
      startedAt: DateTime.parse(json['started_at']),
      plannedEnd: DateTime.parse(json['planned_end']),
      amountDue: (json['estimated_cost'] as num).toDouble(),
    );
  }
}

class VehicleSearchService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> searchByLicensePlate(String plate) async {
    try {
      final response = await _apiClient.get(
        'officer/search/plate/',
        queryParameters: {'plate': plate.toUpperCase()},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'vehicle': VehicleSearchModel.fromJson(response.data),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Vehicle not found'};
    }
    return {'success': false, 'message': 'Unknown error'};
  }

  Future<Map<String, dynamic>> startSession(
    String vehicleId,
    String zoneId,
    double durationHours,
  ) async {
    try {
      final response = await _apiClient.post(
        'officer/parking/start/',
        data: {
          'vehicle_id': vehicleId,
          'zone_id': zoneId,
          'duration_hours': durationHours,
        },
      );

      if (response.statusCode == 201) {
        return {'success': true, 'session': response.data['session']};
      }
      return {
        'success': false,
        'message': response.data['error'] ?? 'Failed to start session',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
