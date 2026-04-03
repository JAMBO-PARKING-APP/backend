import 'package:dio/dio.dart';
import 'package:parking_officer_app/core/api_client.dart';
import 'package:parking_officer_app/features/auth/models/vehicle_model.dart';

class VehicleService {
  final ApiClient _apiClient = ApiClient();

  Future<List<VehicleModel>> getVehicles() async {
    final response = await _apiClient.get('user/vehicles/');
    final payload = response.data;

    final List<dynamic> data;
    if (payload is List) {
      data = payload;
    } else if (payload is Map && payload['results'] is List) {
      data = payload['results'] as List<dynamic>;
    } else {
      data = [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((v) => VehicleModel.fromJson(v))
        .toList();
  }

  Future<VehicleModel> createVehicle({
    required String licensePlate,
    required String make,
    required String model,
    required String color,
  }) async {
    final response = await _apiClient.post(
      'user/vehicles/',
      data: {
        'license_plate': licensePlate,
        'make': make,
        'model': model,
        'color': color,
      },
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return VehicleModel.fromJson(response.data as Map<String, dynamic>);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }
}

