import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parking_user_app/core/api_client.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ApiClient _apiClient = ApiClient();
  StreamSubscription<Position>? _positionStreamSubscription;
  DateTime? _lastUpdateTime;

  // Settings
  static const int _updateIntervalSeconds = 60;
  static const int _distanceFilterMeters = 50;

  Future<void> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    // 2. Request permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return;
    }

    // 3. Get current position immediately
    try {
      Position position = await Geolocator.getCurrentPosition();
      _sendLocationUpdate(position);
    } catch (e) {
      debugPrint('Error getting initial location: $e');
    }

    // 4. Listen for updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _distanceFilterMeters,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _handlePositionUpdate(position);
          },
        );
  }

  void _handlePositionUpdate(Position position) {
    final now = DateTime.now();
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inSeconds < _updateIntervalSeconds) {
      return; // Too soon
    }

    _sendLocationUpdate(position);
    _lastUpdateTime = now;
  }

  Future<void> _sendLocationUpdate(Position position) async {
    try {
      await _apiClient.post(
        'location/',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'is_driver_app': true, // or false depending on app
        },
      );
      debugPrint(
        'Location updated: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      debugPrint('Failed to send location update: $e');
    }
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}
