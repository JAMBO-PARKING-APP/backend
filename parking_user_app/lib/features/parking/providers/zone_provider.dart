import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parking_user_app/features/parking/models/zone_model.dart';
import 'package:parking_user_app/features/parking/services/zone_service.dart';

class ZoneProvider with ChangeNotifier {
  final ZoneService _zoneService = ZoneService();
  List<Zone> _zones = [];
  bool _isLoading = false;

  List<Zone> get zones => _zones;
  bool get isLoading => _isLoading;

  Future<void> fetchZones() async {
    _isLoading = true;
    notifyListeners();
    _zones = await _zoneService.getZones();
    _isLoading = false;
    notifyListeners();
  }

  // --- Phase 7: Recent Zones ---
  List<String> _recentZoneIds = [];
  List<String> get recentZoneIds => _recentZoneIds;

  Future<void> loadRecentZones() async {
    final storage = await SharedPreferences.getInstance();
    _recentZoneIds = storage.getStringList('recent_zones') ?? [];
    notifyListeners();
  }

  Future<void> addToRecent(String zoneId) async {
    final storage = await SharedPreferences.getInstance();
    _recentZoneIds = storage.getStringList('recent_zones') ?? [];
    _recentZoneIds.remove(zoneId); // Remove if exists to move to top
    _recentZoneIds.insert(0, zoneId);
    if (_recentZoneIds.length > 5) _recentZoneIds.removeLast();
    await storage.setStringList('recent_zones', _recentZoneIds);
    notifyListeners();
  }

  List<Zone> get recentZones {
    return _recentZoneIds
        .map((id) => _zones.where((z) => z.id == id).firstOrNull)
        .whereType<Zone>()
        .toList();
  }
}
