import 'package:parking_user_app/core/api_client.dart';
import 'package:dio/dio.dart';
import 'package:parking_user_app/features/auth/models/user_model.dart';
import 'package:parking_user_app/core/storage_manager.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StorageManager _storageManager = StorageManager();

  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final response = await _apiClient.post(
        'auth/login/',
        data: {'phone': phoneNumber, 'password': password},
      );

      if (response.statusCode == 200) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];
        final userData = response.data['user'];

        await _storageManager.saveTokens(access, refresh);
        return {'success': true, 'user': User.fromJson(userData)};
      }
    } catch (e) {
      return {'success': false, 'message': 'Login failed'};
    }
    return {'success': false, 'message': 'Unknown error'};
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    String? confirmPassword,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _apiClient.post(
        'auth/register/',
        data: {
          'phone': phone,
          'password': password,
          'password_confirm': confirmPassword ?? password,
          if (email != null) 'email': email,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        },
      );
      if (response.statusCode == 201) {
        return {'success': true, 'message': response.data['message']};
      }
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final errorData = e.response!.data;
        String errorMessage = 'Registration failed';
        if (errorData is Map) {
          errorMessage = errorData.values.first.toString();
        }
        return {'success': false, 'message': errorMessage};
      }
      return {'success': false, 'message': 'Registration failed'};
    }
    return {'success': false, 'message': 'Registration failed'};
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final response = await _apiClient.post(
        'auth/verify-otp/',
        data: {'phone': phone, 'otp': otp},
      );
      if (response.statusCode == 200) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];
        final userData = response.data['user'];

        await _storageManager.saveTokens(access, refresh);
        return {'success': true, 'user': User.fromJson(userData)};
      }
    } catch (e) {
      return {'success': false, 'message': 'Verification failed'};
    }
    return {'success': false, 'message': 'Verification failed'};
  }

  Future<bool> resendOtp(String phone) async {
    try {
      final response = await _apiClient.post(
        'auth/resend-otp/',
        data: {'phone': phone},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storageManager.clearAuthData();
  }

  Future<User?> getProfile() async {
    try {
      final response = await _apiClient.get('profile/');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<bool> updateProfilePhoto(String filePath) async {
    try {
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        'profile_photo': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _apiClient.patch('profile/', data: formData);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
