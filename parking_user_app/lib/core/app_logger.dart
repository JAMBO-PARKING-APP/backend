import 'package:flutter/foundation.dart';

class AppLogger {
  void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  void error(String message, [Object? error]) {
    debugPrint('[ERROR] $message${error == null ? '' : ' ($error)'}');
  }
}
