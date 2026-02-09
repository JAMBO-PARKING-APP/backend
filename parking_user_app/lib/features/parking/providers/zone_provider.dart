import 'package:flutter/material.dart';
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
}
