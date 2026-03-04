import 'package:dio/dio.dart';
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
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['reservation'];
        if (data != null) {
          return Reservation.fromJson(data);
        }
      }

      final errorMsg = response.data is Map ? response.data['error'] : null;
      throw errorMsg ??
          'Failed to create reservation: Status ${response.statusCode}';
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to create reservation';
      if (data is Map) {
        message =
            data['error'] ?? data['detail'] ?? data.values.first.toString();
      }
      throw message;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<bool> cancelReservation(String reservationId) async {
    try {
      final response = await _apiClient.post(
        'reservations/$reservationId/cancel/',
      );
      if (response.statusCode == 200) return true;

      final errorMsg = response.data is Map ? response.data['error'] : null;
      throw errorMsg ??
          'Failed to cancel reservation: Status ${response.statusCode}';
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to cancel reservation';
      if (data is Map) {
        message =
            data['error'] ?? data['detail'] ?? data.values.first.toString();
      }
      throw message;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<bool> confirmReservationWallet(String reservationId) async {
    try {
      final response = await _apiClient.post(
        'reservations/$reservationId/confirm-wallet/',
      );
      if (response.statusCode == 200) return true;

      final errorMsg = response.data is Map ? response.data['error'] : null;
      throw errorMsg ??
          'Failed to confirm reservation: Status ${response.statusCode}';
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to confirm reservation';
      if (data is Map) {
        message =
            data['error'] ?? data['detail'] ?? data.values.first.toString();
      }
      throw message;
    } catch (e) {
      throw e.toString();
    }
  }
}
