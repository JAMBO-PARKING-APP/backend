import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageManager {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_json';

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _tokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<void> saveUserJson(String json) async {
    await _storage.write(key: _userKey, value: json);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: _userKey);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}
