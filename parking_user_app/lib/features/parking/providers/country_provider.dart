import 'package:flutter/foundation.dart';
import 'package:parking_user_app/core/api_client.dart';
import 'package:parking_user_app/core/storage_manager.dart';
import 'package:parking_user_app/features/common/models/country_model.dart';

class CountryProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final StorageManager _storage = StorageManager();
  List<Country> _countries = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Country> get countries => _countries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCountries() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.get('user/countries/');
      final dynamic payload = response.data;
      final List<dynamic> records;
      if (payload is List) {
        records = payload;
      } else if (payload is Map && payload['results'] is List) {
        records = payload['results'] as List<dynamic>;
      } else if (payload is Map && payload['countries'] is List) {
        records = payload['countries'] as List<dynamic>;
      } else {
        throw const FormatException('The country response was not a list.');
      }
      _countries = records
          .whereType<Map>()
          .map((country) => Country.fromJson(country.cast<String, dynamic>()))
          .toList(growable: false);
      if (_countries.isEmpty) {
        throw const FormatException('No supported countries were returned.');
      }
    } catch (error) {
      _errorMessage = 'Unable to load supported countries: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCountry(String isoCode) async {
    if (!_countries.any((country) => country.code == isoCode)) {
      throw ArgumentError.value(isoCode, 'isoCode', 'Unsupported country code');
    }
    await _storage.saveSelectedCountryCode(isoCode);
    notifyListeners();
  }
}
