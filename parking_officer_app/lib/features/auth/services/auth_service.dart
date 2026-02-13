import 'package:dio/dio.dart';

import 'package:parking_officer_app/core/api_client.dart';
import 'package:parking_officer_app/features/auth/models/user_model.dart';
import 'package:parking_officer_app/core/storage_manager.dart';
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
        'user/auth/login/', // Relative to base URL api/
        data: {'phone': phoneNumber, 'password': password},
      );

      if (response.statusCode == 200) {
        final access = response.data['access'];
        final refresh = response.data['refresh'];
        final userData = response.data['user'];

        // Security check: Only allow officers and admins
        if (userData['role'] != 'officer' && userData['role'] != 'admin') {
          return {
            'success': false,
            'message': 'Access denied. Only officers can use this app.',
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

  String _handleDioError(DioException e) {
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
        return 'Server error. Please try again later.';
      default:
        return data?['error'] ??
            data?['detail'] ??
            'Login failed. Please try again.';
    }
  }

  Future<void> logout() async {
    await _storageManager.clearAuthData();
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
}
