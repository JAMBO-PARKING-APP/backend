import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:parking_user_app/core/models/country_config.dart';
import 'package:parking_user_app/core/api_client.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme_mode';

  late SharedPreferences _prefs;
  String? _locale; // Null means follow system
  ThemeMode _themeMode = ThemeMode.system;

  String get locale => _locale ?? 'system';
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
      // Default to null to follow system language
      _locale = null;
    }
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }

    notifyListeners();

    // Auto-detect country in background
    _detectAndFetchConfig();
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
      }
      notifyListeners();
    }
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
}
