import 'package:flutter/material.dart';
import 'package:parking_user_app/features/parking/models/reservation_model.dart';
import 'package:parking_user_app/features/parking/services/reservation_service.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationService _reservationService = ReservationService();
  List<Reservation> _reservations = [];
  bool _isLoading = false;

  List<Reservation> get reservations => _reservations;
  bool get isLoading => _isLoading;

  Future<void> fetchReservations() async {
    _isLoading = true;
    notifyListeners();
    _reservations = await _reservationService.getReservations();
    _isLoading = false;
    notifyListeners();
  }

  Future<Reservation?> createReservation({
    required String vehicleId,
    required String zoneId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final reservation = await _reservationService.createReservation(
      vehicleId: vehicleId,
      zoneId: zoneId,
      startTime: startTime,
      endTime: endTime,
    );
    if (reservation != null) await fetchReservations();
    return reservation;
  }

  Future<bool> cancelReservation(String reservationId) async {
    final success = await _reservationService.cancelReservation(reservationId);
    if (success) await fetchReservations();
    return success;
  }
}
