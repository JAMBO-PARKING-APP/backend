import 'package:flutter/material.dart';
import 'package:parking_officer_app/features/parking/models/zone_model.dart';
import 'package:parking_officer_app/features/parking/models/parking_session_model.dart';
import 'package:parking_officer_app/features/parking/services/zone_service.dart';

class ZoneProvider with ChangeNotifier {
  final ZoneService _zoneService = ZoneService();

  List<Zone> _zones = [];
  bool _isLoading = false;

  Zone? _selectedZone;
  List<ParkingSession> _activeSessions = [];

  List<Zone> get zones => _zones;
  bool get isLoading => _isLoading;
  Zone? get selectedZone => _selectedZone;
  List<ParkingSession> get activeSessions => _activeSessions;

  Future<void> fetchZones() async {
    _isLoading = true;
    notifyListeners();
    // Fetch officer's assigned zones from new API
    _zones = await _zoneService.getOfficerZones();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectZone(String zoneId) async {
    _isLoading = true;
    _selectedZone = null;
    _activeSessions = [];
    notifyListeners();

    final result = await _zoneService.getZoneSessions(zoneId);
    if (result.containsKey('zone')) {
      _selectedZone = result['zone'];
      _activeSessions = result['sessions'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> searchVehicle(String plate) async {
    return await _zoneService.searchVehicle(plate);
  }
}
