import 'package:flutter/material.dart';
import 'package:parking_officer_app/features/auth/models/vehicle_model.dart';
import 'package:parking_officer_app/features/auth/services/vehicle_service.dart';

class VehicleProvider with ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();

  List<VehicleModel> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchVehicles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vehicles = await _vehicleService.getVehicles();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

