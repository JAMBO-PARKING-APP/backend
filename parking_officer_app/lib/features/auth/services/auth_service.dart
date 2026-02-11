import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    } catch (e) {
      String message = 'Login failed';
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
          message = e.response?.data['error'] ?? 'Invalid credentials';
        }
      }
      return {'success': false, 'message': message};
    }
    return {'success': false, 'message': 'Unknown error'};
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
}
