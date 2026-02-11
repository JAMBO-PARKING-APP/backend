import 'package:dio/dio.dart';
import 'package:parking_officer_app/core/api_client.dart';
import 'package:parking_officer_app/features/enforcement/models/officer_status_model.dart';
import 'package:parking_officer_app/features/enforcement/models/qr_scan_model.dart';

class OfficerService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> toggleOnlineStatus(
    bool goOnline, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        'officer/status/toggle/',
        data: {
          'is_online': goOnline,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        final statusData = response.data['status'];
        return {
          'success': true,
          'status': OfficerStatus.fromJson(statusData),
          'message': response.data['message'],
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['error'] ?? 'Failed to toggle status',
      };
    }
    return {'success': false, 'message': 'Unknown error'};
  }

  Future<Map<String, dynamic>> getOfficerStatus() async {
    try {
      final response = await _apiClient.get('officer/status/');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': OfficerStatus.fromJson(response.data),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to get officer status'};
    }
    return {'success': false, 'message': 'Unknown error'};
  }

  Future<List<QRCodeScan>> getQRScans() async {
    try {
      final response = await _apiClient.get('officer/scans/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return data.map((json) => QRCodeScan.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<List<QRCodeScan>> getActivityLogs() async {
    try {
      final response = await _apiClient.get('officer/logs/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return data.map((json) => QRCodeScan.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<Map<String, dynamic>> scanQRCode(
    String sessionId,
    String qrData, {
    bool endSession = false,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        'officer/qr-scan/',
        data: {
          'session_id': sessionId,
          'qr_data': qrData,
          'end_session': endSession,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': response.data['message'],
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['error'] ?? 'Scan failed',
      };
    }
    return {'success': false, 'message': 'Unknown error'};
  }
}
