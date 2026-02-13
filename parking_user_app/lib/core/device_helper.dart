import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const _storage = FlutterSecureStorage();
  static const String _deviceIdKey = 'device_unique_id';

  /// Get or generate unique device ID
  static Future<String> getDeviceId() async {
    // Check if we already have a device ID stored
    final storedId = await _storage.read(key: _deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }

    // Generate new device ID
    const uuid = Uuid();
    final deviceId = uuid.v4();

    // Store for future use
    await _storage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }

  /// Get device information for logging
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

  /// Clear device ID (for logout)
  static Future<void> clearDeviceId() async {
    await _storage.delete(key: _deviceIdKey);
  }
}
