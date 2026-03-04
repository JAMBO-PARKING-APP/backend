import 'package:flutter/foundation.dart';
import 'package:parking_officer_app/core/api_client.dart';

class QRVerificationService {
  final ApiClient _apiClient = ApiClient();

  /// Verify QR code session
  Future<Map<String, dynamic>> verifyQRCode(String sessionId) async {
    try {
      final response = await _apiClient.post(
        'officer/verify-qr/',
        data: {'session_id': sessionId},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'valid': response.data['valid'] ?? false,
          'session': response.data['session'],
          'message': response.data['message'] ?? 'Session verified',
        };
      } else {
        return {
          'success': false,
          'valid': false,
          'message': response.data['error'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      debugPrint('Error verifying QR code: $e');
      return {
        'success': false,
        'valid': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
