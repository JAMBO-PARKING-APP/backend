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

  OfficerStatus? get officerStatus => _officerStatus;
  List<QRCodeScan> get qrScans => _qrScans;
  List<QRCodeScan> get activityLogs => _activityLogs;
  bool get isLoading => _isLoading;
  bool get isOnline => _officerStatus?.isOnline ?? false;
  String? get errorMessage => _errorMessage;

  Future<bool> toggleOnlineStatus(
    bool goOnline, {
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _officerService.toggleOnlineStatus(
      goOnline,
      latitude: latitude,
      longitude: longitude,
    );

    if (result['success']) {
      _officerStatus = result['status'];
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchOfficerStatus() async {
    _isLoading = true;
    notifyListeners();

    final result = await _officerService.getOfficerStatus();
    if (result['success']) {
      _officerStatus = result['status'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchQRScans() async {
    _isLoading = true;
    notifyListeners();

    final scans = await _officerService.getQRScans();
    _qrScans = scans;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchActivityLogs() async {
    _isLoading = true;
    notifyListeners();

    final logs = await _officerService.getActivityLogs();
    _activityLogs = logs;

    _isLoading = false;
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
