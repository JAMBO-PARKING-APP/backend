import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupPermissionService {
  static const _requestedKeyPrefix = 'startup_permissions_requested_v2_';

  static Future<void> requestOnFirstLaunch(BuildContext context) async {
    final preferences = await SharedPreferences.getInstance();
    if (!context.mounted) return;

    await _requestPermission(
      context,
      permission: Permission.notification,
      preferences: preferences,
      requestKey: '${_requestedKeyPrefix}notifications',
      title: 'Allow notifications',
      rationale:
          'Space Officer sends updates about assignments, parking activity, '
          'and enforcement actions. Allow notifications so you do not miss '
          'important work updates.',
      deniedMessage:
          'You can continue using Space Officer, but work updates will not '
          'appear as notifications.',
    );
    if (!context.mounted) return;

    await _requestPermission(
      context,
      permission: Permission.camera,
      preferences: preferences,
      requestKey: '${_requestedKeyPrefix}camera',
      title: 'Allow camera access',
      rationale:
          'Space Officer uses the camera to scan parking QR codes and take evidence photos for violations. You can still enter a plate manually if you decline.',
      deniedMessage:
          'You can continue using Space Officer, but QR scanning and evidence '
          'photos will be unavailable.',
    );
    if (!context.mounted) return;

    await _requestPermission(
      context,
      permission: Permission.locationWhenInUse,
      preferences: preferences,
      requestKey: '${_requestedKeyPrefix}location',
      title: 'Allow location access',
      rationale:
          'Your location helps show nearby parking zones, update your on-duty location, and add the location to enforcement reports. Location-based features may be limited if you decline.',
      deniedMessage:
          'You can continue using Space Officer, but nearby zone and '
          'location-based reporting features may be limited.',
    );
  }

  static Future<void> _requestPermission(
    BuildContext context, {
    required Permission permission,
    required SharedPreferences preferences,
    required String requestKey,
    required String title,
    required String rationale,
    required String deniedMessage,
  }) async {
    if (!context.mounted) return;
    final currentStatus = await permission.status;
    if (currentStatus.isGranted ||
        currentStatus.isProvisional ||
        !context.mounted) {
      return;
    }

    final alreadyRequested = preferences.getBool(requestKey) ?? false;
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(alreadyRequested ? 'Permission needed' : title),
        content: Text(
          alreadyRequested
              ? '$deniedMessage Enable access in Settings.'
              : rationale,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          if (alreadyRequested)
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(false);
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continue'),
            ),
        ],
      ),
    );
    if (!context.mounted || shouldRequest != true || alreadyRequested) {
      return;
    }

    PermissionStatus status;
    try {
      status = await permission.request();
      await preferences.setBool(requestKey, true);
    } on PlatformException catch (error) {
      debugPrint('Unable to request $permission permission: $error');
      return;
    }

    if (status.isGranted || status.isProvisional || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permission not granted'),
        content: Text('$deniedMessage You can change this in Settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue'),
          ),
          if (status.isPermanentlyDenied || status.isDenied)
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }
}
