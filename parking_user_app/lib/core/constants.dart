import 'dart:io' show Platform;

class AppConstants {
  // When testing via ngrok expose, use the external URL. Otherwise fall back to local dev host.
  static bool useNgrok = true;
  static const String ngrokBase = 'https://70b4-154-227-132-66.ngrok-free.app/api/user/';

  static String get baseUrl {
    if (useNgrok) return ngrokBase;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000/api/user/';
  }

  static const String appName = 'Jambo Park';
}
