import 'package:flutter/foundation.dart';
import 'package:parking_user_app/core/api_client.dart';

class WalletProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  double? _balance;
  String _currency = 'UGX';
  String _currencySymbol = 'UGX';
  bool _isLoading = false;
  String? _errorMessage;

  double? get balance => _balance;
  String get currency => _currency;
  String get currencySymbol => _currencySymbol;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.get('user/wallet/balance/');
      final data = (response.data as Map).cast<String, dynamic>();
      _balance = double.tryParse(data['balance']?.toString() ?? '');
      _currency = data['currency']?.toString() ?? 'UGX';
      _currencySymbol = data['currency_symbol']?.toString() ?? _currency;
    } catch (error) {
      _errorMessage = 'Unable to load wallet: $error';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
