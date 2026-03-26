import 'package:flutter/material.dart';
import 'package:parking_officer_app/features/enforcement/models/officer_status_model.dart';
import 'package:parking_officer_app/features/enforcement/models/qr_scan_model.dart';
import 'package:parking_officer_app/features/enforcement/services/officer_service.dart';

class OfficerProvider with ChangeNotifier {
  final OfficerService _officerService = OfficerService();

  OfficerStatus? _officerStatus;
  List<QRCodeScan> _qrScans = [];
  List<QRCodeScan> _activityLogs = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _dailyScans = 0;
  int _dailyViolations = 0;

  OfficerStatus? get officerStatus => _officerStatus;
  List<QRCodeScan> get qrScans => _qrScans;
  List<QRCodeScan> get activityLogs => _activityLogs;
  bool get isLoading => _isLoading;
  bool get isOnline => _officerStatus?.isOnline ?? false;
  String? get errorMessage => _errorMessage;
  int get dailyScans => _dailyScans;
  int get dailyViolations => _dailyViolations;

  Future<bool> toggleOnlineStatus(
    bool goOnline, {
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _officerService.toggleOnlineStatus(
        goOnline,
        latitude: latitude,
        longitude: longitude,
      );

      if (result['success']) {
        _officerStatus = result['status'];
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error toggling online status: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOfficerStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _officerService.getOfficerStatus();
      if (result['success']) {
        _officerStatus = result['status'];
      }
    } catch (e) {
      debugPrint('Error fetching officer status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchQRScans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final scans = await _officerService.getQRScans();
      _qrScans = scans;
    } catch (e) {
      debugPrint('Error fetching QR scans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActivityLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final logs = await _officerService.getActivityLogs();
      _activityLogs = logs;
      _updateDailyStats();
    } catch (e) {
      debugPrint('Error fetching activity logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateDailyStats() {
    final now = DateTime.now();
    final todayLogs = _activityLogs.where((log) {
      final date = log.createdAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();

    _dailyScans = todayLogs.where((log) => log.scanStatus == 'valid').length;

    notifyListeners();
  }

  void incrementDailyViolations() {
    _dailyViolations++;
    notifyListeners();
  }

  Future<Map<String, dynamic>> scanQRCode(
    String sessionId,
    String qrData, {
    bool endSession = false,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _officerService.scanQRCode(
      sessionId,
      qrData,
      endSession: endSession,
      latitude: latitude,
      longitude: longitude,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> refreshAllData() async {
    await Future.wait([
      fetchOfficerStatus(),
      fetchQRScans(),
      fetchActivityLogs(),
    ]);
  }
}
