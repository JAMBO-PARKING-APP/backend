import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupPermissionService {
  static const _requestedKeyPrefix = 'startup_permissions_requested_v3_';

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
          'SPACE sends updates about your parking sessions, reservations, '
          'and account activity. Allow notifications so you do not miss '
          'important parking updates.',
      deniedMessage:
          'You can continue using SPACE, but parking updates will not appear '
          'as notifications.',
    );
    if (!context.mounted) return;

    await _requestLocationPermission(context, preferences);
    if (!context.mounted) return;

    await _requestPermission(
      context,
      permission: Permission.camera,
      preferences: preferences,
      requestKey: '${_requestedKeyPrefix}camera',
      title: 'Allow camera access',
      rationale:
          'SPACE uses the camera when you choose to take a photo for your '
          'profile. You can select an existing photo instead or continue '
          'without changing your profile picture.',
      deniedMessage:
          'You can continue using SPACE and choose an existing profile '
          'photo. Camera capture will be unavailable unless you enable '
          'camera access in Settings.',
    );
  }

  static Future<void> _requestLocationPermission(
    BuildContext context,
    SharedPreferences preferences,
  ) async {
    const requestKey = '${_requestedKeyPrefix}location';
    final currentStatus = await Geolocator.checkPermission();
    if (currentStatus == LocationPermission.whileInUse ||
        currentStatus == LocationPermission.always ||
        !context.mounted) {
      return;
    }

    final alreadyRequested = preferences.getBool(requestKey) ?? false;
    const deniedMessage =
        'You can continue using SPACE, but nearby parking and other '
        'location-based features may be unavailable.';
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          alreadyRequested ? 'Location access needed' : 'Allow location access',
        ),
        content: Text(
          alreadyRequested
              ? '$deniedMessage Enable Location access in Settings.'
              : 'SPACE uses your location while you use the app to find '
                    'nearby parking zones, choose a parking area, and share '
                    'your location for active parking services.',
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
    if (!context.mounted || shouldRequest != true || alreadyRequested) return;

    LocationPermission status;
    try {
      status = await Geolocator.requestPermission();
      await preferences.setBool(requestKey, true);
    } on PlatformException catch (error) {
      debugPrint('Unable to request location permission: $error');
      status = LocationPermission.denied;
    }
    if (status == LocationPermission.whileInUse ||
        status == LocationPermission.always ||
        !context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location access not granted'),
        content: Text('$deniedMessage You can enable it in Settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue'),
          ),
          if (status == LocationPermission.deniedForever ||
              status == LocationPermission.denied)
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
      status = PermissionStatus.denied;
    }
    if (status.isGranted || status.isProvisional || !context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permission not granted'),
        content: Text(deniedMessage),
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
