import 'package:flutter/material.dart';
import 'package:parking_user_app/features/auth/models/user_model.dart';
import 'package:parking_user_app/features/auth/services/auth_service.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'package:parking_user_app/core/fcm_service.dart';
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

  bool _hasRequestedPermissions = false;
  bool get hasRequestedPermissions => _hasRequestedPermissions;
  String get currencySymbol => user?.countryDetails?.currencySymbol ?? 'UGX';

  Future<void> checkAuth() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final storage = StorageManager();
    _hasRequestedPermissions = await storage.hasRequestedPermissions();

    if (!_hasRequestedPermissions) {
      _status = AuthStatus.unauthenticated; // logic in specific screen
      notifyListeners();
      return;
    }

    final user = await _authService.getProfile();
    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
    } else {
      // Fallback: if tokens exist locally, consider user authenticated offline
      final token = await storage.getAccessToken();
      final userJson = await storage.getUserJson();
      if (token != null && userJson != null) {
        try {
          _user = User.fromJson(json.decode(userJson));
          _status = AuthStatus.authenticated;
        } catch (_) {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    debugPrint('[AuthProvider] ====== STARTING LOGIN ======');
    debugPrint('[AuthProvider] Phone: $phoneNumber');

    final result = await _authService.login(phoneNumber, password);

    debugPrint('[AuthProvider] Login result success: ${result['success']}');

    if (result['success']) {
      _user = result['user'];
      _status = AuthStatus.authenticated;
      debugPrint('[AuthProvider] ✓ User authenticated successfully');
      debugPrint('[AuthProvider] User: ${_user?.firstName} ${_user?.lastName}');
      debugPrint('[AuthProvider] Status changed to: $_status');

      // Register FCM token after successful login
      FCMService().registerToken().then((success) {
        debugPrint('[AuthProvider] FCM token registration: $success');
      });

      notifyListeners();
      debugPrint('[AuthProvider] Notified listeners - UI should update now');
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message'];
      debugPrint('[AuthProvider] ✗ Login failed: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String phoneNumber,
    required String password,
    String? confirmPassword,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      phone: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
      email: email,
      firstName: firstName,
      lastName: lastName,
    );

    _status = AuthStatus.unauthenticated;
    if (!result['success']) {
      _errorMessage = result['message'];
    }
    notifyListeners();
    return result['success'];
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.verifyOtp(phoneNumber, otp);
    if (result['success']) {
      _user = result['user'];
      _status = AuthStatus.authenticated;

      // Register FCM token after successful OTP verification
      FCMService().registerToken().then((success) {
        debugPrint('[AuthProvider] FCM token registration: $success');
      });

      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Unregister FCM token before logout
    await FCMService().unregisterToken();

    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfilePhoto(String filePath) async {
    final success = await _authService.updateProfilePhoto(filePath);
    if (success) {
      await checkAuth(); // Refresh profile
    }
    return success;
  }

  Future<bool> deleteAccount() async {
    final success = await _authService.deleteAccount();
    if (success) {
      final storage = StorageManager();
      await storage.clearAuthData();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
    return success;
  }
}
