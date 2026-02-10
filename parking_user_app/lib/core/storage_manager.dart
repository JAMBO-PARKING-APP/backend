import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class StorageManager {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceSessionKey = 'device_session_id';
  static const _userKey = 'user_json';
  static const _permissionsRequestedKey = 'permissions_requested';

  Future<void> saveTokens(String access, String refresh) async {
    debugPrint('[StorageManager] Saving tokens...');
    await _storage.write(key: _tokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
    debugPrint('[StorageManager] Tokens saved successfully');
  }

  Future<void> saveDeviceSession(String deviceSession) async {
    await _storage.write(key: _deviceSessionKey, value: deviceSession);
  }

  Future<String?> getDeviceSession() async {
    return await _storage.read(key: _deviceSessionKey);
  }

  Future<void> saveUserJson(String json) async {
    await _storage.write(key: _userKey, value: json);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: _userKey);
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _tokenKey);
    debugPrint(
      '[StorageManager] Retrieved token: ${token != null ? "Found (${token.substring(0, 20)}...)" : "NULL"}',
    );
    return token;
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> setPermissionsRequested(bool value) async {
    await _storage.write(
      key: _permissionsRequestedKey,
      value: value.toString(),
    );
  }

  Future<bool> hasRequestedPermissions() async {
    final value = await _storage.read(key: _permissionsRequestedKey);
    return value == 'true';
  }
}
