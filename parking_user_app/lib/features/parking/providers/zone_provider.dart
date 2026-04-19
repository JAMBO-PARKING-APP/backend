import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:parking_user_app/core/location_service.dart';
import 'package:parking_user_app/features/parking/models/zone_model.dart';
import 'package:parking_user_app/features/parking/models/parking_session_model.dart';
import 'package:parking_user_app/features/parking/services/zone_service.dart';

class ZoneProvider with ChangeNotifier {
  final ZoneService _zoneService = ZoneService();

  List<Zone> _zones = [];
  bool _isLoading = false;

  Zone? _selectedZone;
  // Compatibility: some copied officer widgets still reference this.
  // User app currently doesn't show active sessions from this provider.
  List<ParkingSession> _activeSessions = [];

  List<Zone> get zones => _zones;
  bool get isLoading => _isLoading;
  Zone? get selectedZone => _selectedZone;
  List<ParkingSession> get activeSessions => _activeSessions;

  Future<void> fetchZones() async {
    _isLoading = true;
    notifyListeners();

    final fetched = await _zoneService.getZones();
    final pos = await LocationService().getCurrentPosition();
    if (pos != null) {
      _zones = fetched
          .map((z) => z.copyWith(
                distanceKm: _haversineKm(
                  pos.latitude,
                  pos.longitude,
                  z.latitude,
                  z.longitude,
                ),
              ))
          .toList()
        ..sort((a, b) => (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9));
    } else {
      _zones = fetched;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectZone(String zoneId) async {
    final match = _zones.where((z) => z.id == zoneId).toList();
    _selectedZone = match.isNotEmpty ? match.first : null;
    _activeSessions = [];
    notifyListeners();
  }

  // Compatibility shim for copied officer code.
  Future<Map<String, dynamic>?> searchVehicle(String plate) async {
    return null;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}
