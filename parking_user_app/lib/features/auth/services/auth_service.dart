import 'package:dio/dio.dart';

import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/auth/models/user_model.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:parking_user_app/core/constants.dart';
import 'dart:convert';
import 'dart:io';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StorageManager _storageManager = StorageManager();

  Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = 'Unknown';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
      }

      final response = await _apiClient.post(
        'user/auth/register/',
        data: {
          'phone': phoneNumber,
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          'device_model': deviceModel,
          'app_version': AppConstants.appVersion,
          'device_os': Platform.isAndroid ? 'android' : 'ios',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];
        final userData = response.data['user'];

        if (userData['role'] != 'driver') {
          return {
            'success': false,
            'message': 'Access denied. This app is for drivers only.',
          };
        }

        await _storageManager.saveTokens(access, refresh);
        await _storageManager.saveUserJson(jsonEncode(userData));

        return {'success': true, 'user': User.fromJson(userData)};
      }

      return {
        'success': false,
        'message': 'Registration failed. Please try again.',
      };
    } on DioException catch (e) {
      final message = _handleDioError(e, operation: 'creating your account');
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> login(
    String phoneNumber,
    String password,
  ) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = 'Unknown';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
      }

      final response = await _apiClient.post(
        'user/auth/login/',
        data: {
          'phone': phoneNumber,
          'password': password,
          'device_model': deviceModel,
          'app_version': AppConstants.appVersion,
          'device_os': Platform.isAndroid ? 'android' : 'ios',
        },
      );

      if (response.statusCode == 200) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];
        final userData = response.data['user'];

        // User app: allow only drivers (do not include zone owners/host features).
        if (userData['role'] != 'driver') {
          return {
            'success': false,
            'message': 'Access denied. This app is for drivers only.',
          };
        }

        await _storageManager.saveTokens(access, refresh);
        await _storageManager.saveUserJson(json.encode(userData));

        return {'success': true, 'user': User.fromJson(userData)};
      }
    } on DioException catch (e) {
      String message = _handleDioError(e);
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
    return {'success': false, 'message': 'Unknown error'};
  }

  String _handleDioError(DioException e, {String operation = 'signing in'}) {
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
        return _messageFromResponse(data, fields: const ['detail', 'error']) ??
            'Invalid phone number or password.';
      case 400:
        final responseMessage = _messageFromResponse(
          data,
          fields: const ['error', 'detail'],
        );
        if (responseMessage?.toLowerCase().contains(
                  'with this phone number already exists',
                ) ==
                true ||
            responseMessage?.toLowerCase().contains(
                  'phone number already exists',
                ) ==
                true) {
          return 'An account with this phone number already exists. '
              'Sign in instead, or use a different phone number.';
        }
        return responseMessage ?? 'Please check your details and try again.';
      case 404:
        return operation == 'creating your account'
            ? 'Account registration is unavailable right now. Please try again later.'
            : 'User not found or service unavailable.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return _messageFromResponse(data, fields: const ['error', 'detail']) ??
            'There was a problem $operation. Please try again.';
    }
  }

  String? _messageFromResponse(dynamic data, {required List<String> fields}) {
    if (data is Map) {
      for (final field in fields) {
        final value = data[field];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }

      final details = data['details'];
      if (details is Map) {
        final messages = <String>[];
        for (final entry in details.entries) {
          final value = entry.value;
          final fieldMessages = value is List ? value : [value];
          for (final message in fieldMessages) {
            final text = message.toString().trim();
            if (text.isNotEmpty) {
              messages.add('${entry.key}: $text');
            }
          }
        }
        if (messages.isNotEmpty) return messages.join('\n');
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }

  Future<void> logout() async {
    await _storageManager.clearAuthData();
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _apiClient.delete('user/auth/delete-account/');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await logout();
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to delete account'};
    } catch (e) {
      return {'success': false, 'message': 'Error deleting account'};
    }
  }

  Future<User?> getProfile() async {
    try {
      final response = await _apiClient.get('user/profile/');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('user/profile/', data: data);
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to update profile'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'profile_photo': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _apiClient.patch('user/profile/', data: formData);
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to update profile picture'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
