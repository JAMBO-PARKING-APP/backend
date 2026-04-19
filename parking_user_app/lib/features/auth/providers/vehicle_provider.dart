import 'package:flutter/material.dart';
import 'package:parking_user_app/features/auth/models/vehicle_model.dart';
import 'package:parking_user_app/features/auth/services/vehicle_service.dart';

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

  Future<void> deleteVehicle(String vehicleId) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _vehicleService.deleteVehicle(vehicleId);
      _vehicles.removeWhere((v) => v.id == vehicleId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createVehicle({
    required String licensePlate,
    required String make,
    required String model,
    required String color,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final vehicle = await _vehicleService.createVehicle(
        licensePlate: licensePlate,
        make: make,
        model: model,
        color: color,
      );
      _vehicles = [vehicle, ..._vehicles];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

