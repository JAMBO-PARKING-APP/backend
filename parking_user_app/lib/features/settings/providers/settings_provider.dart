import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme_mode';

  late SharedPreferences _prefs;
  String _locale = 'en';
  ThemeMode _themeMode = ThemeMode.system;

  String get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Locale get currentLocale => Locale(_locale);

  SettingsProvider() {
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _locale = _prefs.getString(_languageKey) ?? 'en';
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    if (_locale != locale) {
      _locale = locale;
      await _prefs.setString(_languageKey, locale);
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

  List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('sw'),
    Locale('fr'),
    Locale('es'),
  ];
}
