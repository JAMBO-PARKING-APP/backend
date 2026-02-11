import 'dart:io' show Platform;

class AppConstants {
  static bool useNgrok = true;
  static const String ngrokBase =
      'https://1850-154-227-132-66.ngrok-free.app/api/';

  static String get baseUrl {
    if (useNgrok) return ngrokBase;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000/api/';
  }

  static const String appName = 'Jambo Officer';
}
