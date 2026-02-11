import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';
import 'package:parking_user_app/features/parking/services/parking_service.dart';
import 'package:parking_user_app/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ParkingProvider with ChangeNotifier {
  final ParkingService _parkingService = ParkingService();
  List<ParkingSession> _sessions = [];
  List<Zone> _zones = [];
  bool _isLoading = false;
  Timer? _timer;

  List<ParkingSession> get sessions => _sessions;
  List<ParkingSession> get activeSessions =>
      _sessions.where((s) => s.status == 'active').toList();
  List<Zone> get zones => _zones;
  bool get isLoading => _isLoading;

  ParkingProvider() {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (activeSessions.isNotEmpty) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchSessions() async {
    _isLoading = true;
    notifyListeners();
    _sessions = await _parkingService.getSessions();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchZones() async {
    _isLoading = true;
    notifyListeners();
    _zones = await _parkingService.getZones();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> startParking({
    required BuildContext context,
    required String vehicleId,
    required String zoneId,
    double durationHours = 1.0,
  }) async {
    final success = await _parkingService.startParking(
      vehicleId: vehicleId,
      zoneId: zoneId,
      durationHours: durationHours,
    );
    if (success) {
      await fetchSessions();
      // Refresh wallet balance in AuthProvider
      if (context.mounted) {
        await Provider.of<AuthProvider>(context, listen: false).checkAuth();
      }
    }
    return success;
  }

  Future<bool> extendParking(String sessionId, int additionalHours) async {
    final success = await _parkingService.extendParking(
      sessionId,
      additionalHours,
    );
    if (success) await fetchSessions();
    return success;
  }

  Future<bool> endParking(String sessionId) async {
    final success = await _parkingService.endParking(sessionId);
    if (success) await fetchSessions();
    return success;
  }
}
