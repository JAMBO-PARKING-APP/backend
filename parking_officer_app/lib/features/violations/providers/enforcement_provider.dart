import 'dart:io';
import 'package:flutter/material.dart';
import 'package:parking_officer_app/features/violations/services/enforcement_service.dart';

class EnforcementProvider with ChangeNotifier {
  final EnforcementService _enforcementService = EnforcementService();
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  Future<bool> issueViolation({
    String? vehicleId,
    String? vehiclePlate,
    required String zoneId,
    required String type,
    required String description,
    required double fineAmount,
    required double lat,
    required double lng,
    List<File>? evidence,
    String? sessionId,
  }) async {
    _isProcessing = true;
    notifyListeners();

    final success = await _enforcementService.issueViolation(
      vehicleId: vehicleId,
      vehiclePlate: vehiclePlate,
      zoneId: zoneId,
      type: type,
      description: description,
      fineAmount: fineAmount,
      lat: lat,
      lng: lng,
      evidence: evidence,
      sessionId: sessionId,
    );

    _isProcessing = false;
    notifyListeners();
    return success;
  }

  Future<void> logAction(String action, {Map<String, dynamic>? details}) async {
    // In a real app, we might get lat/lng from a location provider
    await _enforcementService.logAction(action: action, details: details);
  }
}
