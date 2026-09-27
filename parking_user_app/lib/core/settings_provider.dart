import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _languageKey = 'selected_language';
  static const _supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('de'),
    Locale('sw'),
    Locale('es'),
    Locale('ar'),
  ];

  Locale _currentLocale = const Locale('en');
  bool _initialized = false;
  bool _hasSelectedLanguage = false;

  Locale get currentLocale => _currentLocale;
  List<Locale> get supportedLocales => _supportedLocales;
  bool get isInitialized => _initialized;
  bool get hasSelectedLanguage => _hasSelectedLanguage;

  SettingsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final code = preferences.getString(_languageKey);
      if (code != null &&
          supportedLocales.any((locale) => locale.languageCode == code)) {
        _currentLocale = Locale(code);
        _hasSelectedLanguage = true;
      }
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(Locale locale) async {
    if (!supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    )) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported language');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, locale.languageCode);
    _currentLocale = locale;
    _hasSelectedLanguage = true;
    notifyListeners();
  }
}
