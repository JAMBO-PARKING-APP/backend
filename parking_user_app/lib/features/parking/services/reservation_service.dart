import 'package:dio/dio.dart';
import 'package:parking_officer_app/core/api_client.dart';
import 'package:parking_officer_app/features/parking/models/reservation_model.dart';

class ReservationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ReservationModel>> listReservations() async {
    final response = await _apiClient.get('user/reservations/');
    final payload = response.data;

    final List<dynamic> data;
    if (payload is List) {
      data = payload;
    } else if (payload is Map) {
      if (payload['results'] is List) {
        data = payload['results'] as List<dynamic>;
      } else if (payload['reservations'] is List) {
        data = payload['reservations'] as List<dynamic>;
      } else {
        data = [];
      }
    } else {
      data = [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((r) => ReservationModel.fromJson(r))
        .toList();
  }

  Future<void> cancelReservation(String reservationId) async {
    await _apiClient.post('user/reservations/$reservationId/cancel/', data: {});
  }

  Future<void> confirmWallet(String reservationId) async {
    await _apiClient.post('user/reservations/$reservationId/confirm-wallet/', data: {});
  }

  Future<ReservationModel> createReservation({
    required String vehicleId,
    required String zoneId,
    required DateTime reservedFrom,
    required DateTime reservedUntil,
    required bool confirmImmediately,
    required String paymentMethod, // wallet or pesapal
  }) async {
    final response = await _apiClient.post(
      'user/reservations/create/',
      data: {
        'vehicle_id': vehicleId,
        'zone_id': zoneId,
        // Backend serializer accepts either reserved_from/reserved_until or start_time/end_time.
        'reserved_from': reservedFrom.toIso8601String(),
        'reserved_until': reservedUntil.toIso8601String(),
        'confirm_immediately': confirmImmediately,
        'payment_method': paymentMethod,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['reservation'] is Map<String, dynamic>) {
        return ReservationModel.fromJson(data['reservation'] as Map<String, dynamic>);
      }
      if (data is Map<String, dynamic>) {
        // Some implementations may return reservation at top-level.
        return ReservationModel.fromJson(data);
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }
  Future<Map<String, dynamic>> startParkingFromReservation(String reservationId, double lat, double lng) async {
    final response = await _apiClient.post(
      'user/reservations/$reservationId/start/',
      data: {
        'lat': lat,
        'lng': lng,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}

