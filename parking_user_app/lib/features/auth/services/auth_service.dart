import 'package:parking_user_app/core/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:parking_user_app/features/auth/models/user_model.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'package:parking_user_app/core/device_helper.dart';
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
        data: {
          'phone': phoneNumber,
          'password': password,
          'app_version': await DeviceHelper.getAppVersion(),
          'device_model': await DeviceHelper.getDeviceModel(),
          'device_os': DeviceHelper.getDeviceOS(),
        },
      );

      if (response.statusCode == 200) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];
        final userData = response.data['user'];

        debugPrint('[AuthService] ✅ Login response received (200)');
        debugPrint('[AuthService] Response keys: ${response.data.keys}');
        debugPrint('[AuthService] User data: $userData');
        
        debugPrint('[AuthService] Saving tokens...');
        await _storageManager.saveTokens(access, refresh);
        
        // Extract jti (JWT ID) from token payload for reference
        // The backend uses this to enforce single-device login
        try {
          final parts = access.split('.');
          if (parts.length == 3) {
            final payload = base64Url.normalize(parts[1]);
            final decoded = utf8.decode(base64Url.decode(payload));
            final map = json.decode(decoded);
            // Log the jti for debugging purposes
            debugPrint('[AuthService] ✅ Token JTI: ${map['jti']}');
          }
        } catch (e) {
          debugPrint('[AuthService] ⚠️ Could not extract token payload: $e');
        }

        try {
          await _storageManager.saveUserJson(json.encode(userData));
          debugPrint('[AuthService] ✅ User data saved to storage');
        } catch (e) {
          debugPrint('[AuthService] ⚠️ Could not save user JSON: $e');
        }

        // Parse user data - this is critical
        try {
          final user = User.fromJson(userData);
          debugPrint('[AuthService] ✅ User parsed successfully: ${user.firstName} ${user.lastName}');
          return {'success': true, 'user': user};
        } catch (e) {
          debugPrint('[AuthService] ❌ FAILED to parse user JSON: $e');
          debugPrint('[AuthService] User JSON was: ${json.encode(userData)}');
          return {
            'success': false,
            'message': 'Failed to process user data: $e',
          };
        }
      }
    } on DioException catch (e) {
      debugPrint('[AuthService] Login DioException: ${e.message}');
      debugPrint('[AuthService] Response data: ${e.response?.data}');
      String message = _handleDioError(e);
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('[AuthService] Login Unexpected error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
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
      debugPrint('[AuthService] Registering phone: $phone, email: $email');
      final response = await _apiClient.post(
        'auth/register/',
        data: {
          'phone': phone,
          'password': password,
          'password_confirm': confirmPassword ?? password,
          if (email?.isNotEmpty ?? false) 'email': email,
          if (firstName?.isNotEmpty ?? false) 'first_name': firstName,
          if (lastName?.isNotEmpty ?? false) 'last_name': lastName,
          'app_version': await DeviceHelper.getAppVersion(),
          'device_model': await DeviceHelper.getDeviceModel(),
          'device_os': DeviceHelper.getDeviceOS(),
        },
      );
      if (response.statusCode == 201) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];
        final userData = response.data['user'];

        debugPrint('[AuthService] Registration successful, saving tokens...');
        await _storageManager.saveTokens(access, refresh);
        
        try {
          await _storageManager.saveUserJson(json.encode(userData));
          debugPrint('[AuthService] ✅ User data saved to storage');
        } catch (e) {
          debugPrint('[AuthService] ⚠️ ERROR saving user data to storage: $e');
          // Still return success if tokens were saved
        }

        debugPrint('[AuthService] Returning success with user data');
        return {'success': true, 'user': User.fromJson(userData)};
      }
    } on DioException catch (e) {
      debugPrint('[AuthService] Registration DioException: ${e.message}');
      debugPrint('[AuthService] Response data: ${e.response?.data}');
      String message = _handleDioError(e);
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('[AuthService] Registration unexpected error: $e');
      return {'success': false, 'message': 'Registration failed'};
    }
    return {'success': false, 'message': 'Registration failed'};
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, {String? email}) async {
    try {
      debugPrint('[AuthService] Verifying OTP for $phone, code: $otp');
      final response = await _apiClient.post(
        'auth/verify-otp/',
        data: {
          'phone': phone, 
          'otp': otp,
          if (email != null) 'email': email,
          'app_version': await DeviceHelper.getAppVersion(),
          'device_model': await DeviceHelper.getDeviceModel(),
          'device_os': DeviceHelper.getDeviceOS(),
        },
      );
      if (response.statusCode == 200) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];
        final userData = response.data['user'];

        await _storageManager.saveTokens(access, refresh);
        
        // Extract and log jti for debugging
        try {
          final parts = access.split('.');
          if (parts.length == 3) {
            final payload = base64Url.normalize(parts[1]);
            final decoded = utf8.decode(base64Url.decode(payload));
            final map = json.decode(decoded);
            debugPrint('[AuthService] OTP Verification - Token JTI: ${map['jti']}');
          }
        } catch (e) {
          debugPrint('[AuthService] Could not extract OTP token payload: $e');
        }

        try {
          await _storageManager.saveUserJson(json.encode(userData));
          debugPrint('[AuthService] ✅ User data saved to storage');
        } catch (e) {
          debugPrint('[AuthService] ⚠️ ERROR saving user data to storage: $e');
          // Still return success if tokens were saved
        }

        return {'success': true, 'user': User.fromJson(userData)};
      }
    } on DioException catch (e) {
      debugPrint('[AuthService] verifyOtp DioException: ${e.message}');
      debugPrint('[AuthService] Response data: ${e.response?.data}');
      String message = _handleDioError(e);
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('[AuthService] verifyOtp unexpected error: $e');
      return {'success': false, 'message': 'Verification failed'};
    }
    return {'success': false, 'message': 'Verification failed'};
  }

  Future<bool> resendOtp(String phone, {String? email}) async {
    try {
      debugPrint('[AuthService] Resending OTP for $phone');
      final response = await _apiClient.post(
        'auth/resend-otp/',
        data: {
          'phone': phone,
          if (email != null) 'email': email,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('[AuthService] resendOtp DioException: ${e.message}');
      debugPrint('[AuthService] Response data: ${e.response?.data}');
      return false;
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
    } on DioException catch (e) {
      debugPrint('[AuthService] getProfile DioException: ${e.message}');
      debugPrint('[AuthService] Response data: ${e.response?.data}');
      return null;
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
    } on DioException catch (e) {
      debugPrint('[AuthService] updateProfilePhoto DioException: ${e.message}');
      return false;
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
    } on DioException catch (e) {
      debugPrint('[AuthService] deleteAccount DioException: ${e.message}');
      return false;
    } catch (e) {
      return false;
    }
  }

  String _handleDioError(DioException e) {
    debugPrint('[AuthService] _handleDioError: ${e.type}');
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server took too long to respond. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    switch (statusCode) {
      case 401:
        return data?['detail'] ??
            data?['error'] ??
            'Invalid phone number or password.';
      case 400:
        final errors =
            data?['error'] ?? data?['detail'] ?? 'Invalid input provided.';
        if (errors is Map) {
          return errors.values.first.toString();
        }
        return errors.toString();
      case 404:
        return 'User not found or service unavailable.';
      case 500:
        final errors = data?['error'] ?? data?['detail'] ?? 'Server error. Please try again later.';
        return errors.toString();
      default:
        return data?['error'] ??
            data?['detail'] ??
            'Action failed. Please try again.';
    }
  }
}
