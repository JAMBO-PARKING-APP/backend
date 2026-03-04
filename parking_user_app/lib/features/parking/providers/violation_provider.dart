import 'package:flutter/material.dart';
import 'package:parking_user_app/features/parking/models/violation_model.dart';
import 'package:parking_user_app/features/parking/services/violation_service.dart';

class ViolationProvider with ChangeNotifier {
  final ViolationService _violationService = ViolationService();
  List<Violation> _violations = [];
  bool _isLoading = false;
  int _unpaidCount = 0;
  double _totalUnpaidAmount = 0.0;

  List<Violation> get violations => _violations;
  bool get isLoading => _isLoading;
  int get unpaidCount => _unpaidCount;
  double get totalUnpaidAmount => _totalUnpaidAmount;

  Future<void> fetchViolations() async {
    _isLoading = true;
    notifyListeners();

    _violations = await _violationService.getViolations();
    final summary = await _violationService.getViolationsSummary();

    _unpaidCount = summary['unpaid_count'] ?? 0;
    _totalUnpaidAmount =
        double.tryParse(summary['total_amount']?.toString() ?? '0') ?? 0.0;

    _isLoading = false;
    notifyListeners();
  }
}
