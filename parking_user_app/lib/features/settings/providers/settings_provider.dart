import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme';

  late SharedPreferences _prefs;
  String _locale = 'en';
  bool _isDarkMode = false;

  String get locale => _locale;
  bool get isDarkMode => _isDarkMode;

  Locale get currentLocale => Locale(_locale);

  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsProvider() {
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _locale = _prefs.getString(_languageKey) ?? 'en';
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    if (_locale != locale) {
      _locale = locale;
      await _prefs.setString(_languageKey, locale);
      notifyListeners();
    }
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _prefs.setBool(_themeKey, isDark);
      notifyListeners();
    }
  }

  void toggleTheme() async {
    await setTheme(!_isDarkMode);
  }

  List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('sw'),
    Locale('fr'),
    Locale('es'),
  ];
}
