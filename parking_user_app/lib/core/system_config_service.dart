import 'dart:io' show Platform;

import 'package:parking_user_app/core/api_client.dart';

class SystemConfig {
  final String minVersion;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String? updateUrl;

  const SystemConfig({
    required this.minVersion,
    required this.forceUpdate,
    required this.maintenanceMode,
    this.updateUrl,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) => SystemConfig(
    minVersion:
        (Platform.isIOS ? json['min_ios_version'] : json['min_android_version'])
            ?.toString() ??
        '1.0.0',
    forceUpdate: json['force_update'] == true,
    maintenanceMode: json['maintenance_mode'] == true,
    updateUrl: json['app_update_url']?.toString(),
  );
}

class SystemConfigService {
  final ApiClient _api = ApiClient();

  Future<SystemConfig> fetchSystemConfig() async {
    final response = await _api.get('user/system/config/');
    if (response.data is! Map) {
      throw const FormatException(
        'The system configuration response was invalid.',
      );
    }
    return SystemConfig.fromJson(
      (response.data as Map).cast<String, dynamic>(),
    );
  }
}
