import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  ConnectivityProvider() {
    _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _setConnectivity,
      onError: (Object error) =>
          debugPrint('Connectivity stream failed: $error'),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      _setConnectivity(await _connectivity.checkConnectivity());
    } catch (error) {
      debugPrint('Unable to check connectivity: $error');
    }
  }

  void _setConnectivity(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    if (_isOffline == offline) return;
    _isOffline = offline;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
