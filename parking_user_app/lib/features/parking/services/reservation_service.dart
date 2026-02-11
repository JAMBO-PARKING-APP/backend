import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/parking/models/reservation_model.dart';

class ReservationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Reservation>> getReservations() async {
    try {
      final response = await _apiClient.get('reservations/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return data.map((json) => Reservation.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<Reservation?> createReservation({
    required String vehicleId,
    required String zoneId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _apiClient.post(
        'reservations/create/',
        data: {
          'vehicle_id': vehicleId,
          'zone_id': zoneId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['reservation'];
        if (data != null) {
          return Reservation.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    try {
      final response = await _apiClient.post(
        'reservations/$reservationId/cancel/',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
