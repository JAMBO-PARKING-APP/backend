import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/api_client.dart';

class AIChatService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> askAI(String query) async {
    try {
      // Get current location if possible
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (e) {
        // Ignore location errors, just proceed without it
        debugPrint("Location error: $e");
      }

      final response = await _apiClient.post(
        'support/ask/',
        data: {
          'query': query,
          if (position != null) 'latitude': position.latitude,
          if (position != null) 'longitude': position.longitude,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'response': response.data['response'],
          'suggested_actions': response.data['suggested_actions'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': response.data['error'] ?? 'Failed to get response',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
