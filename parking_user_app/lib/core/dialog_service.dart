import 'package:flutter/material.dart';

class DialogService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void showNoInternetDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Check if dialog is already open to avoid stacking
    // This is a simple check; for production, you might want a more robust state
    // But since we can't easily check active dialogs without context traversing,
    // we'll rely on the user dismissing it or a simple flag if needed.

    showDialog(
      context: context,
      barrierDismissible: false, // User must acknowledge
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.signal_wifi_off, color: Colors.red),
            SizedBox(width: 10),
            Text('No Internet'),
          ],
        ),
        content: const Text(
          'Please check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showSuccessDialog({
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isLoadingShown = false;
  static String _currentMessage = '';
  static StateSetter? _messageSetter;
  static DateTime? _loadingStartTime;

  static void showLoading({String message = 'Please wait...'}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (_isLoadingShown) {
      _currentMessage = message;
      _messageSetter?.call(() {}); // Trigger rebuild of the dialog content
      return;
    }

    _isLoadingShown = true;
    _currentMessage = message;
    _loadingStartTime = DateTime.now();
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (context, setState) {
            _messageSetter = setState;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    _currentMessage,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    ).then((_) {
      _isLoadingShown = false;
      _messageSetter = null;
      _loadingStartTime = null;
    });

    // Safety fallback: auto-hide loader after 30 seconds to prevent total app hang
    Future.delayed(const Duration(seconds: 30), () {
      if (_isLoadingShown &&
          _loadingStartTime != null &&
          DateTime.now().difference(_loadingStartTime!) >=
              const Duration(seconds: 29)) {
        hideLoading();
      }
    });
  }

  static void hideLoading() {
    if (_isLoadingShown) {
      _isLoadingShown = false;
      _loadingStartTime = null;
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Use rootNavigator: true to ensure we pop the dialog from the top stack
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }
}
