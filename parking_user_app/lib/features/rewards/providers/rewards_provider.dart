import 'package:flutter/foundation.dart';
import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/features/rewards/models/loyalty_model.dart';

class RewardsProvider with ChangeNotifier {
  final ApiClient _apiClient;

  LoyaltyAccount? _account;
  List<PointTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  RewardsProvider(this._apiClient);

  LoyaltyAccount? get account => _account;
  List<PointTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLoyaltyData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final balanceData = await _apiClient.getLoyaltyBalance();
      _account = LoyaltyAccount.fromJson(balanceData);

      final historyData = await _apiClient.getLoyaltyHistory();
      _transactions = historyData
          .map((json) => PointTransaction.fromJson(json))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching loyalty data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
