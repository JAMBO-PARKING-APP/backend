import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/auth/models/vehicle_model.dart';

class VehicleService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _apiClient.get('vehicles/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return data.map((v) => Vehicle.fromJson(v)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<bool> addVehicle({
    required String licensePlate,
    required String make,
    required String model,
    required String color,
  }) async {
    try {
      final response = await _apiClient.post(
        'vehicles/',
        data: {
          'license_plate': licensePlate,
          'make': make,
          'model': model,
          'color': color,
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeVehicle(String id) async {
    try {
      final response = await _apiClient.dio.delete('vehicles/$id/');
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
