import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:parking_user_app/core/models/country_config.dart';
import 'package:parking_user_app/core/models/system_config.dart';
import 'package:parking_user_app/core/constants.dart';
import 'package:parking_user_app/core/api_client.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _hasSelectedLanguageKey = 'has_selected_language';
  static const String _hasSelectedCountryKey = 'has_selected_country';
  static const String _themeKey = 'app_theme_mode';

  late SharedPreferences _prefs;
  String? _locale; // Null means follow system
  bool _hasSelectedLanguage = false;
  ThemeMode _themeMode = ThemeMode.dark;

  List<CountryCode> _activeCountries = [];
  bool _isLoadingCountries = false;
  bool _hasSelectedCountry = false;
  
  String get locale => _locale ?? 'system';
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  bool get hasSelectedCountry => _hasSelectedCountry;
  List<CountryCode> get activeCountries => _activeCountries;
  bool get isLoadingCountries => _isLoadingCountries;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Locale? get currentLocale => _locale != null ? Locale(_locale!) : null;

  SettingsProvider() {
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.containsKey(_languageKey)) {
      _locale = _prefs.getString(_languageKey);
    } else {
      _locale = null;
    }
    _hasSelectedLanguage = _prefs.getBool(_hasSelectedLanguageKey) ?? false;
    _hasSelectedCountry = _prefs.getBool(_hasSelectedCountryKey) ?? false;
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    notifyListeners();

    // Auto-detect country and fetch configs in background
    _detectAndFetchConfig();
    fetchSystemConfig();
  }

  Future<void> _detectAndFetchConfig() async {
    final detectedCountry = await detectCountry();
    if (detectedCountry != null) {
      _isoCountryCode = detectedCountry;
      await fetchCountryConfig(detectedCountry);
    }
  }

  String? _isoCountryCode;
  String? get isoCountryCode => _isoCountryCode;

  Future<void> setLocale(String? localeCode) async {
    final effectiveLocale = localeCode == 'system' ? null : localeCode;
    if (_locale != effectiveLocale) {
      _locale = effectiveLocale;
      if (effectiveLocale == null) {
        await _prefs.remove(_languageKey);
      } else {
        await _prefs.setString(_languageKey, effectiveLocale);
        // Removed: await markLanguageSelected(); // Don't auto-mark, wait for user to press Continue
      }
      notifyListeners();
    }
  }

  Future<void> markLanguageSelected() async {
    _hasSelectedLanguage = true;
    await _prefs.setBool(_hasSelectedLanguageKey, true);
    notifyListeners();
  }

  Future<void> markCountrySelected() async {
    _hasSelectedCountry = true;
    await _prefs.setBool(_hasSelectedCountryKey, true);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _prefs.setString(_themeKey, mode.toString());
      notifyListeners();
    }
  }

  void toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setTheme(ThemeMode.light);
    } else {
      await setTheme(ThemeMode.dark);
    }
  }

  Future<String?> detectCountry() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        return placemarks.first.isoCountryCode;
      }
    } catch (e) {
      debugPrint('Error detecting country: $e');
    }
    return null;
  }

  CountryConfig? _countryConfig;
  CountryConfig get countryConfig =>
      _countryConfig ?? CountryConfig.defaultConfig;

  Future<void> fetchCountryConfig(String countryCode) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('country-config/$countryCode/');
      if (response.statusCode == 200) {
        _countryConfig = CountryConfig.fromJson(response.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching country config: $e');
      _countryConfig = CountryConfig.defaultConfig;
    }
  }

  List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('sw'),
    Locale('fr'),
    Locale('es'),
    Locale('de'),
    Locale('ar'),
  ];

  SystemConfig? _systemConfig;
  SystemConfig get systemConfig => _systemConfig ?? SystemConfig.defaultConfig;

  Future<void> fetchSystemConfig() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('system/config/');
      if (response.statusCode == 200) {
        _systemConfig = SystemConfig.fromJson(response.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching system config: $e');
    }
  }

  Future<void> fetchActiveCountries() async {
    _isLoadingCountries = true;
    notifyListeners();
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get('countries/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _activeCountries = data.map((json) => CountryCode(
          name: json['name'],
          code: json['iso_code'],
          flag: json['flag_emoji'] ?? '🌍',
          dialCode: json['phone_code'] ?? '',
        )).toList();
      }
    } catch (e) {
      debugPrint('Error fetching active countries: $e');
    } finally {
      _isLoadingCountries = false;
      notifyListeners();
    }
  }
}
