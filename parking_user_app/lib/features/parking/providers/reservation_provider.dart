import 'package:flutter/material.dart';
import 'package:parking_officer_app/features/parking/models/reservation_model.dart';
import 'package:parking_officer_app/features/parking/services/reservation_service.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationService _reservationService = ReservationService();

  List<ReservationModel> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReservationModel> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReservations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reservations = await _reservationService.listReservations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelReservation(String reservationId) async {
    await _reservationService.cancelReservation(reservationId);
    await fetchReservations();
  }

  Future<void> confirmReservationWithWallet(String reservationId) async {
    await _reservationService.confirmWallet(reservationId);
    await fetchReservations();
  }
}

