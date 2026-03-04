import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _themeKey = 'app_theme_mode';

  late SharedPreferences _prefs;
  String? _locale; // Null means follow system
  ThemeMode _themeMode = ThemeMode.system;

  String get locale => _locale ?? 'system';
  ThemeMode get themeMode => _themeMode;

  Locale? get currentLocale => _locale != null ? Locale(_locale!) : null;

  List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('sw'),
    Locale('fr'),
    Locale('es'),
    Locale('de'),
    Locale('ar'),
  ];

  SettingsProvider() {
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.containsKey(_languageKey)) {
      _locale = _prefs.getString(_languageKey);
    }
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }

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
}
