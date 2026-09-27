import 'package:flutter/material.dart';
import 'package:parking_officer_app/core/analytics_service.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/services/vehicle_search_service.dart';
import 'package:parking_officer_app/features/parking/services/zone_service.dart';

class NonAppUserSessionProvider with ChangeNotifier {
  NonAppUserSessionProvider({
    VehicleSearchService? sessionService,
    ZoneService? zoneService,
  }) : _sessionService = sessionService ?? VehicleSearchService(),
       _zoneService = zoneService ?? ZoneService();

  final VehicleSearchService _sessionService;
  final ZoneService _zoneService;

  List<Zone> _zones = [];
  Map<String, dynamic>? _session;
  String? _paymentUrl;
  String? _error;
  bool _isLoadingZones = false;
  bool _isSubmitting = false;
  bool _isConfirming = false;
  bool _isPaymentConfirmed = false;

  List<Zone> get zones => _zones;
  Map<String, dynamic>? get session => _session;
  String? get paymentUrl => _paymentUrl;
  String? get error => _error;
  bool get isLoadingZones => _isLoadingZones;
  bool get isSubmitting => _isSubmitting;
  bool get isConfirming => _isConfirming;
  bool get isPaymentConfirmed => _isPaymentConfirmed;

  Future<void> loadZones() async {
    _isLoadingZones = true;
    _error = null;
    notifyListeners();
    _zones = await _zoneService.getZones();
    _isLoadingZones = false;
    notifyListeners();
  }

  Future<bool> createSession({
    required String licensePlate,
    required String driverName,
    required String driverPhone,
    required String zoneId,
    required double durationHours,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    final result = await _sessionService.createGuestSession(
      licensePlate: licensePlate.trim().toUpperCase(),
      driverName: driverName.trim(),
      driverPhone: driverPhone.trim(),
      zoneId: zoneId,
      durationHours: durationHours,
    );
    _isSubmitting = false;
    if (result['success'] == true && result['session'] is Map) {
      _session = Map<String, dynamic>.from(result['session'] as Map);
      _session!['id'] ??= result['session_id'];
      _session!['estimated_cost'] ??= result['amount_due'];
      _paymentUrl = null;
      _isPaymentConfirmed = false;
      AnalyticsService.logEvent(
        name: 'guest_session_created',
        parameters: {
          'duration_hours': durationHours,
          'success': true,
        },
      );
      notifyListeners();
      return true;
    }
    AnalyticsService.logEvent(
      name: 'guest_session_created',
      parameters: {
        'duration_hours': durationHours,
        'success': false,
      },
    );
    _error = result['message']?.toString() ?? 'Could not create guest session';
    notifyListeners();
    return false;
  }

  Future<bool> initiatePayment(String phoneNumber) async {
    final sessionId = _session?['id']?.toString();
    if (sessionId == null || sessionId.isEmpty) {
      _error = 'Create a guest session before starting payment.';
      notifyListeners();
      return false;
    }
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    final result = await _sessionService.initiateGuestPayment(
      sessionId: sessionId,
      phoneNumber: phoneNumber.trim(),
    );
    _isSubmitting = false;
    final paymentUrl = result['payment_url'] ?? result['redirect_url'];
    if (result['success'] == true && paymentUrl != null) {
      _paymentUrl = paymentUrl.toString();
      AnalyticsService.logEvent(
        name: 'guest_payment_initiated',
        parameters: const {'success': true},
      );
      notifyListeners();
      return true;
    }
    AnalyticsService.logEvent(
      name: 'guest_payment_initiated',
      parameters: const {'success': false},
    );
    _error = result['message']?.toString() ?? 'Could not start payment';
    notifyListeners();
    return false;
  }

  Future<bool> confirmPayment() async {
    final sessionId = _session?['id']?.toString();
    if (sessionId == null || sessionId.isEmpty) {
      _error = 'Guest session details are unavailable.';
      notifyListeners();
      return false;
    }
    _isConfirming = true;
    _error = null;
    notifyListeners();
    final result = await _sessionService.confirmGuestSessionPayment(sessionId);
    _isConfirming = false;
    if (result['success'] == true) {
      _isPaymentConfirmed = true;
      AnalyticsService.logEvent(
        name: 'guest_payment_confirmed',
        parameters: const {'success': true},
      );
      _session!['status'] =
          result['session_status'] ??
          result['status_code'] ??
          _session!['status'];
      _session!['payment_status'] =
          result['payment_status'] ?? _session!['payment_status'];
      notifyListeners();
      return true;
    }
    AnalyticsService.logEvent(
      name: 'guest_payment_confirmed',
      parameters: const {'success': false},
    );
    _error = result['message']?.toString() ?? 'Payment has not been confirmed';
    notifyListeners();
    return false;
  }

  void restoreSession(Map<String, dynamic> session) {
    _session = Map<String, dynamic>.from(session);
    _paymentUrl = null;
    _error = null;
    _isPaymentConfirmed =
        session['payment_status'] == 'completed' ||
        session['payment_status'] == 'free';
    notifyListeners();
  }
}
