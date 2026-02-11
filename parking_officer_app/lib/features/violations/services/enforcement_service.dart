import 'dart:io';
import 'package:dio/dio.dart';
import 'package:parking_officer_app/core/api_client.dart';

class EnforcementService {
  final ApiClient _apiClient = ApiClient();

  Future<bool> issueViolation({
    required String vehicleId,
    required String zoneId,
    required String type,
    required String description,
    required double fineAmount,
    required double lat,
    required double lng,
    List<File>? evidence,
    String? sessionId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'vehicle': vehicleId,
        'zone': zoneId,
        'violation_type': type,
        'description': description,
        'fine_amount': fineAmount,
        'latitude': lat,
        'longitude': lng,
        if (sessionId != null) 'parking_session': sessionId,
      });

      // Handle multiple evidence photos
      if (evidence != null && evidence.isNotEmpty) {
        for (int i = 0; i < evidence.length; i++) {
          formData.files.add(
            MapEntry(
              'evidence',
              await MultipartFile.fromFile(
                evidence[i].path,
                filename: 'evidence_$i.jpg',
              ),
            ),
          );
        }
      }

      final response = await _apiClient.post(
        'officer/violations/create/',
        data: formData,
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<void> logAction({
    required String action,
    Map<String, dynamic>? details,
    double? lat,
    double? lng,
  }) async {
    try {
      await _apiClient.post(
        'officer/logs/create/',
        data: {
          'action': action,
          'details': details ?? {},
          if (lat != null) 'latitude': lat,
          if (lng != null) 'longitude': lng,
        },
      );
    } catch (e) {
      // Background logging failure shouldn't block the UI
    }
  }
}
