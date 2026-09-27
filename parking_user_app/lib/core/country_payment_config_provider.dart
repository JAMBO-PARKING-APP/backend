import 'package:flutter/foundation.dart';
import 'package:parking_user_app/core/api_client.dart';

class CountryPaymentConfigProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<String> _paymentMethods = const ['wallet'];
  String _currency = 'UGX';
  String _currencySymbol = 'UGX';
  bool _isLoading = false;
  String? _errorMessage;

  List<String> get paymentMethods => _paymentMethods;
  String get currency => _currency;
  String get currencySymbol => _currencySymbol;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadConfig(String countryCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.get('user/payment-country-config/');
      final data = (response.data as Map).cast<String, dynamic>();
      final country = data['country'];
      _paymentMethods =
          (data['payment_methods'] as List?)
              ?.map((method) => method.toString())
              .toList(growable: false) ??
          const ['wallet'];
      if (country is Map) {
        final values = country.cast<String, dynamic>();
        _currency = values['currency']?.toString() ?? _currency;
        _currencySymbol =
            values['currency_symbol']?.toString() ?? _currencySymbol;
      }
    } catch (error) {
      _errorMessage = 'Unable to load payment options: $error';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
