import 'package:flutter/material.dart';
import 'package:parking_user_app/features/auth/models/vehicle_model.dart';
import 'package:parking_user_app/features/auth/services/vehicle_service.dart';

class VehicleProvider with ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  Future<void> fetchVehicles() async {
    _isLoading = true;
    notifyListeners();

    _vehicles = await _vehicleService.getVehicles();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addVehicle({
    required String licensePlate,
    required String make,
    required String model,
    required String color,
  }) async {
    final success = await _vehicleService.addVehicle(
      licensePlate: licensePlate,
      make: make,
      model: model,
      color: color,
    );
    if (success) {
      await fetchVehicles();
    }
    return success;
  }

  Future<bool> removeVehicle(String id) async {
    final success = await _vehicleService.removeVehicle(id);
    if (success) {
      _vehicles.removeWhere((v) => v.id == id);
      notifyListeners();
    }
    return success;
  }
}
