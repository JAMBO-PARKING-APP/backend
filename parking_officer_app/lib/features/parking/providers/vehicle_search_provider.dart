import 'package:flutter/material.dart';
import 'package:parking_officer_app/features/parking/services/vehicle_search_service.dart';

class VehicleSearchProvider with ChangeNotifier {
  final VehicleSearchService _searchService = VehicleSearchService();

  VehicleSearchModel? _currentVehicle;
  bool _isSearching = false;
  String? _searchError;

  VehicleSearchModel? get currentVehicle => _currentVehicle;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;

  Future<bool> searchVehicle(String licensePlate) async {
    _isSearching = true;
    _searchError = null;
    _currentVehicle = null;
    notifyListeners();

    final result = await _searchService.searchByLicensePlate(licensePlate);

    if (result['success']) {
      _currentVehicle = result['vehicle'];
      _isSearching = false;
      notifyListeners();
      return true;
    } else {
      _searchError = result['message'];
      _isSearching = false;
      notifyListeners();
      return false;
    }
  }

  void clearSearch() {
    _currentVehicle = null;
    _searchError = null;
    notifyListeners();
  }
}
