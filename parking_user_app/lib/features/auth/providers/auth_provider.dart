import 'package:flutter/material.dart';
import 'package:parking_user_app/features/auth/models/user_model.dart';
import 'package:parking_user_app/features/auth/services/auth_service.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'package:parking_user_app/core/fcm_service.dart';
import 'package:parking_user_app/core/websocket_service.dart';
import 'package:parking_user_app/core/background_service.dart';
import 'dart:convert';

import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:parking_user_app/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { authenticated, unauthenticated, authenticating, initial, needsUpdate }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  bool _isInitialLoadComplete = false;

  User? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isInitialLoadComplete => _isInitialLoadComplete;

  bool _hasRequestedPermissions = false;
  bool get hasRequestedPermissions => _hasRequestedPermissions;
  String get currencySymbol => user?.countryDetails?.currencySymbol ?? 'UGX';

  void setInitialLoadComplete() {
    _isInitialLoadComplete = true;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    // 0. Version Check
    final needsUpdate = await _checkVersion();
    if (needsUpdate) {
      _status = AuthStatus.needsUpdate;
      notifyListeners();
      return;
    }

    // Only show global loading if we are NOT already authenticated
    if (_status != AuthStatus.authenticated &&
        _status != AuthStatus.authenticating) {
      _status = AuthStatus.authenticating;
      notifyListeners();
    }

    final storage = StorageManager();
    _hasRequestedPermissions = await storage.hasRequestedPermissions();

    if (!_hasRequestedPermissions) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // 1. Try to load from storage first (Offline-first strategy)
    final token = await storage.getAccessToken();
    final userJson = await storage.getUserJson();

    if (token != null && userJson != null) {
      try {
        _user = User.fromJson(json.decode(userJson));
        _status = AuthStatus.authenticated;
        notifyListeners(); // Validate immediately with cached data
        debugPrint(
          '[AuthProvider] Loaded profile from storage: ${_user?.firstName}',
        );
        // Connect WebSocket after loading from storage
        WebSocketService().connect();
        
        // Initialize Background Service
        initializeBackgroundService();
      } catch (e) {
        debugPrint('[AuthProvider] Error parsing cached user: $e');
      }
    }

    // 2. Refresh from network (Background update)
    if (token != null) {
      try {
        final user = await _authService.getProfile();
        if (user != null) {
          _user = user;
          _status = AuthStatus.authenticated;

          // Persist updated profile
          await storage.saveUserJson(json.encode(user.toJson()));
          debugPrint(
            '[AuthProvider] Updated profile from network and saved to storage',
          );
          
          // Ensure background service is running
          initializeBackgroundService();
          
          notifyListeners();
        } else if (_user == null) {
          // Only set to unauthenticated if we defined no user from storage AND network failed
          // But if network failed with 401, AuthService.getProfile returns null
          // We might want to check validity of token?
          // For now, if we have cached user, we stay authenticated even if network fails (offline mode)
          // If we had no cached user and network fails, we are unauthenticated
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('[AuthProvider] Network profile fetch failed: $e');
        // If we have _user from storage, we stay authenticated (Offline mode)
        if (_user == null) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
      }
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> _checkVersion() async {
    try {
      
      // We rely on SettingsProvider having fetched the config already in SplashScreen
      // But we can double check here or use a safe default
      final settings = SettingsProvider();
      await settings.fetchSystemConfig();
      final config = settings.systemConfig;
      
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final targetVersion = Platform.isAndroid 
          ? config.minAndroidVersion 
          : config.minIosVersion;

      if (_isVersionLower(currentVersion, targetVersion)) {
        debugPrint('[AuthProvider] Version check failed: $currentVersion < $targetVersion');
        return true;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Version check error: $e');
    }
    return false;
  }

  bool _isVersionLower(String current, String target) {
    try {
      List<int> currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      List<int> targetParts = target.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      
      for (int i = 0; i < 3; i++) {
        int c = i < currentParts.length ? currentParts[i] : 0;
        int t = i < targetParts.length ? targetParts[i] : 0;
        if (c < t) return true;
        if (c > t) return false;
      }
    } catch (e) {
      debugPrint('Error comparing versions: $e');
    }
    return false;
  }

  Future<void> completePermissions() async {
    final storage = StorageManager();
    await storage.setPermissionsRequested(true);
    _hasRequestedPermissions = true;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    debugPrint('[AuthProvider] Permissions completed, triggering UI update');
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
      // Connect WebSocket after login
      WebSocketService().connect();
      
      // Initialize Background Service
      initializeBackgroundService();
      
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

    if (result['success']) {
      _user = result['user'];
      _status = AuthStatus.authenticated;
      
      // Register FCM token after successful registration
      FCMService().registerToken().then((success) {
        debugPrint('[AuthProvider] FCM token registration: $success');
      });

      // Connect WebSocket after registration
      WebSocketService().connect();
      
      // Initialize Background Service
      initializeBackgroundService();
      
      notifyListeners();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String otp, {String? email}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.verifyOtp(phoneNumber, otp, email: email);
    if (result['success']) {
      _user = result['user'];
      _status = AuthStatus.authenticated;

      // Register FCM token after successful OTP verification
      FCMService().registerToken().then((success) {
        debugPrint('[AuthProvider] FCM token registration: $success');
      });

      notifyListeners();
      // Connect WebSocket after OTP verification
      WebSocketService().connect();
      return true;
    } else {
      _status = AuthStatus.unauthenticated;
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp(String phoneNumber, {String? email}) async {
    _errorMessage = null;
    notifyListeners();
    final success = await _authService.resendOtp(phoneNumber, email: email);
    if (!success) {
      _errorMessage = 'Failed to resend OTP. Please try again.';
    }
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    // Unregister FCM token before logout
    await FCMService().unregisterToken();

    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;

    // Disconnect WebSocket on logout
    WebSocketService().disconnect();

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
