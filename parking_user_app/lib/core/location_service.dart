import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parking_officer_app/core/api_client.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ApiClient _apiClient = ApiClient();
  StreamSubscription<Position>? _positionStreamSubscription;
  DateTime? _lastUpdateTime;

  static const int _updateIntervalSeconds = 60;
  static const int _distanceFilterMeters =
      30;

  Future<void> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      await _sendLocationUpdate(position);
    } catch (e) {
      debugPrint('Error getting initial location: $e');
    }

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
      return; 
    }

    _sendLocationUpdate(position);
    _lastUpdateTime = now;
  }

  Future<void> _sendLocationUpdate(Position position) async {
    try {
      await _apiClient.post(
        'user/location/',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        },
      );
      debugPrint('[User] Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('[User] Failed to send location update: $e');
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}
