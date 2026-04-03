import 'package:flutter/material.dart';
import 'package:parking_officer_app/features/auth/models/user_model.dart';
import 'package:parking_officer_app/features/auth/services/auth_service.dart';
import 'package:parking_officer_app/core/storage_manager.dart';
import 'package:parking_officer_app/core/fcm_service.dart';
import 'dart:convert';

enum AuthStatus { authenticated, unauthenticated, authenticating, initial }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuth() async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();

      final storage = StorageManager();
      final userJson = await storage.getUserJson();

      if (userJson != null) {
        try {
          _user = User.fromJson(json.decode(userJson));
          print('✅ AuthProvider: User restored from storage');
          print('   - User ID: ${_user?.id}');
          print('   - Phone: ${_user?.phone}');
          print('   - Role: ${_user?.role}');
          print('   - Country: ${_user?.country}');
          print('   - Country Name: ${_user?.countryName}');
          print('   - Country Identifier: ${_user?.countryIdentifier}');
          _status = AuthStatus.authenticated;
          await FCMService().syncTokenWithBackend();
        } catch (e) {
          debugPrint('[AuthProvider] Error parsing user JSON: $e');
          print('❌ AuthProvider: Failed to parse stored user data - $e');
          _status = AuthStatus.unauthenticated;
        }
      } else {
        print('ℹ️ AuthProvider: No stored user data');
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error in checkAuth: $e');
      print('💥 AuthProvider: Exception in checkAuth - $e');
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.login(phoneNumber, password);

      if (result['success']) {
        _user = result['user'];
        print('✅ AuthProvider: User logged in successfully');
        print('   - User ID: ${_user?.id}');
        print('   - Phone: ${_user?.phone}');
        print('   - Role: ${_user?.role}');
        print('   - Country: ${_user?.country}');
        print('   - Country Name: ${_user?.countryName}');
        print('   - Country Identifier: ${_user?.countryIdentifier}');
        _status = AuthStatus.authenticated;
        await FCMService().syncTokenWithBackend();
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = result['message'];
        print('❌ AuthProvider: Login failed - ${result['message']}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error in login: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'An error occurred during login. Please try again.';
      print('💥 AuthProvider: Exception during login - $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String phoneNumber,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final result = await _authService.register(
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
      );

      if (result['success'] == true) {
        _user = result['user'];
        _status = AuthStatus.authenticated;
        await FCMService().syncTokenWithBackend();
        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message']?.toString();
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'An error occurred during registration. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final fresh = await _authService.getProfile();
      if (fresh != null) {
        _user = fresh;
        final storage = StorageManager();
        await storage.saveUserJson(json.encode({
          'id': fresh.id,
          'phone': fresh.phone,
          'first_name': fresh.firstName,
          'last_name': fresh.lastName,
          'email': fresh.email,
          'role': fresh.role,
          'profile_photo': fresh.profilePhoto,
          'country': fresh.country,
          'country_name': fresh.countryName,
        }));
        notifyListeners();
      }
    } catch (_) {}
  }
}
