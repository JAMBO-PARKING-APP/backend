import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const _storage = FlutterSecureStorage();
  static const String _deviceIdKey = 'device_unique_id';

  static Future<String> getDeviceId() async {
    final storedId = await _storage.read(key: _deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }

    const uuid = Uuid();
    final deviceId = uuid.v4();

    await _storage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }

  static Future<String> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return 'Unknown Device';
  }

  static Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (_) {
      return '1.0.0';
    }
  }

  /// Get device model
  static Future<String> getDeviceModel() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.model;
      }
    } catch (_) {}
    return 'Unknown Model';
  }

  /// Get device OS
  static String getDeviceOS() {
    return Platform.isAndroid ? 'android' : 'ios';
  }

  /// Clear device ID (for logout)
  static Future<void> clearDeviceId() async {
    await _storage.delete(key: _deviceIdKey);
  }
}
