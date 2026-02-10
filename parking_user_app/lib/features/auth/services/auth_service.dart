import 'package:parking_user_app/core/api_client.dart';
import 'package:dio/dio.dart';
import 'package:parking_user_app/features/auth/models/user_model.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'dart:convert';

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
        // decode token payload to extract device_session_id if present
        try {
          final parts = access.split('.');
          if (parts.length == 3) {
            final payload = base64Url.normalize(parts[1]);
            final decoded = utf8.decode(base64Url.decode(payload));
            final map = json.decode(decoded);
            if (map['device_session_id'] != null) {
              await _storageManager.saveDeviceSession(
                map['device_session_id'].toString(),
              );
            }
          }
        } catch (_) {}

        // persist user JSON for offline session
        try {
          await _storageManager.saveUserJson(json.encode(userData));
        } catch (_) {}

        return {'success': true, 'user': User.fromJson(userData)};
      }
    } catch (e) {
      String message = 'Login failed';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError) {
          message = 'No internet connection. Please check your network.';
        } else if (e.response?.statusCode == 400 ||
            e.response?.statusCode == 401) {
          message = 'Invalid phone number or password';
          if (e.response?.data is Map && e.response?.data['error'] != null) {
            message = e.response?.data['error'];
          }
        } else if (e.response?.data is Map &&
            e.response?.data['detail'] != null) {
          message = e.response?.data['detail'];
        }
      }
      return {'success': false, 'message': message};
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
        try {
          final parts = access.split('.');
          if (parts.length == 3) {
            final payload = base64Url.normalize(parts[1]);
            final decoded = utf8.decode(base64Url.decode(payload));
            final map = json.decode(decoded);
            if (map['device_session_id'] != null) {
              await _storageManager.saveDeviceSession(
                map['device_session_id'].toString(),
              );
            }
          }
        } catch (_) {}

        try {
          await _storageManager.saveUserJson(json.encode(userData));
        } catch (_) {}

        return {'success': true, 'user': User.fromJson(userData)};
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError) {
          return {'success': false, 'message': 'No internet connection'};
        }
        if (e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data.values.isNotEmpty) {
            return {'success': false, 'message': data.values.first.toString()};
          }
        }
      }
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

  Future<bool> deleteAccount() async {
    try {
      final response = await _apiClient.delete('auth/delete-account/');
      if (response.statusCode == 204) {
        await _storageManager.clearAuthData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
