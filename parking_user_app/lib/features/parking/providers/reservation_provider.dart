import 'package:flutter/material.dart';
import 'package:parking_user_app/core/analytics_service.dart';
import 'package:parking_user_app/core/location_service.dart';
import 'package:parking_user_app/features/parking/models/reservation_model.dart';
import 'package:parking_user_app/features/parking/services/reservation_service.dart';

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

  Future<bool> startReservation(String reservationId) async {
    try {
      final position = await LocationService().getCurrentPosition();
      if (position == null) {
        throw StateError('Location is required to start a reserved session.');
      }
      await _reservationService.startParkingFromReservation(
        reservationId,
        position.latitude,
        position.longitude,
      );
      await fetchReservations();
      AnalyticsService.logEvent(
        name: 'reservation_started',
        parameters: const {'success': true},
      );
      return true;
    } catch (e) {
      AnalyticsService.logEvent(
        name: 'reservation_started',
        parameters: const {'success': false},
      );
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createReservation({
    required String vehicleId,
    required String zoneId,
    required DateTime reservedFrom,
    required DateTime reservedUntil,
    required bool confirmImmediately,
    required String paymentMethod,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _reservationService.createReservation(
        vehicleId: vehicleId,
        zoneId: zoneId,
        reservedFrom: reservedFrom,
        reservedUntil: reservedUntil,
        confirmImmediately: confirmImmediately,
        paymentMethod: paymentMethod,
      );
      await fetchReservations();
      AnalyticsService.logEvent(
        name: 'reservation_created',
        parameters: {
          'payment_method': paymentMethod,
          'confirmed_immediately': confirmImmediately,
          'success': true,
        },
      );
      return true;
    } catch (e) {
      AnalyticsService.logEvent(
        name: 'reservation_created',
        parameters: {
          'payment_method': paymentMethod,
          'confirmed_immediately': confirmImmediately,
          'success': false,
        },
      );
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
