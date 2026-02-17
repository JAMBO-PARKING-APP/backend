import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

abstract class AppLocalizations {
  const AppLocalizations();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      _getLocalization(locale.languageCode),
    );
  }

  static AppLocalizations _getLocalization(String languageCode) {
    switch (languageCode) {
      case 'sw':
        return _SwahiliLocalizations();
      case 'fr':
        return _FrenchLocalizations();
      case 'es':
        return _SpanishLocalizations();
      case 'de':
        return _GermanLocalizations();
      case 'ar':
        return _ArabicLocalizations();
      case 'en':
      default:
        return _EnglishLocalizations();
    }
  }

  // Common UI strings
  String get appTitle;
  String get zones;
  String get scan;
  String get search;
  String get chat;
  String get history;
  String get profile;
  String get logout;
  String get zoneMonitor;
  String get dailyScans;
  String get dailyViolations;
  String get online;
  String get offline;
  String get activeZones;
  String get refresh;
  String get noActiveZones;
  String get officerStatus;
  String get goOnline;
  String get goOffline;
  String get zoneCode;
  String get full;
  String get occupied;
  String get available;
  String get total;
}

class _EnglishLocalizations extends AppLocalizations {
  @override
  String get appTitle => 'Space Officer';
  @override
  String get zones => 'Zones';
  @override
  String get scan => 'Scan';
  @override
  String get search => 'Search';
  @override
  String get chat => 'Chat';
  @override
  String get history => 'History';
  @override
  String get profile => 'Profile';
  @override
  String get logout => 'Logout';
  @override
  String get zoneMonitor => 'Zone Monitor';
  @override
  String get dailyScans => 'Daily Scans';
  @override
  String get dailyViolations => 'Violations';
  @override
  String get online => 'ONLINE';
  @override
  String get offline => 'OFFLINE';
  @override
  String get activeZones => 'Active Zones';
  @override
  String get refresh => 'Refresh';
  @override
  String get noActiveZones => 'No active zones found.';
  @override
  String get officerStatus => 'Officer Status';
  @override
  String get goOnline => 'Go Online';
  @override
  String get goOffline => 'Go Offline';
  @override
  String get zoneCode => 'Zone Code';
  @override
  String get full => 'Full';
  @override
  String get occupied => 'Occupied';
  @override
  String get available => 'Available';
  @override
  String get total => 'Total';
}

class _SwahiliLocalizations extends AppLocalizations {
  @override
  String get appTitle => 'Space Officer';
  @override
  String get zones => 'Maeneo';
  @override
  String get scan => 'Skena';
  @override
  String get search => 'Tafuta';
  @override
  String get chat => 'Mazungumzo';
  @override
  String get history => 'Historia';
  @override
  String get profile => 'Wasifu';
  @override
  String get logout => 'Toka';
  @override
  String get zoneMonitor => 'Ufuatiliaji wa Maeneo';
  @override
  String get dailyScans => 'Skena za Leo';
  @override
  String get dailyViolations => 'Ukiukaji';
  @override
  String get online => 'UKO MTANDAONI';
  @override
  String get offline => 'HAUKO MTANDAONI';
  @override
  String get activeZones => 'Maeneo Yanayotumika';
  @override
  String get refresh => 'Refresh';
  @override
  String get noActiveZones => 'Hakuna maeneo yanayotumika.';
  @override
  String get officerStatus => 'Hali ya Ofisa';
  @override
  String get goOnline => 'Ingia Mtandaoni';
  @override
  String get goOffline => 'Toka Mtandaoni';
  @override
  String get zoneCode => 'Nambari ya Eneo';
  @override
  String get full => 'Imejaa';
  @override
  String get occupied => 'Imetumika';
  @override
  String get available => 'Inapatikana';
  @override
  String get total => 'Jumla';
}

class _FrenchLocalizations extends AppLocalizations {
  @override
  String get appTitle => 'Space Officer';
  @override
  String get zones => 'Zones';
  @override
  String get scan => 'Scanner';
  @override
  String get search => 'Recherche';
  @override
  String get chat => 'Chat';
  @override
  String get history => 'Histoire';
  @override
  String get profile => 'Profil';
  @override
  String get logout => 'Déconnexion';
  @override
  String get zoneMonitor => 'Moniteur de Zone';
  @override
  String get dailyScans => 'Scans Quotidiens';
  @override
  String get dailyViolations => 'Violations';
  @override
  String get online => 'EN LIGNE';
  @override
  String get offline => 'HORS LIGNE';
  @override
  String get activeZones => 'Zones Actives';
  @override
  String get refresh => 'Rafraîchir';
  @override
  String get noActiveZones => 'Aucune zone active trouvée.';
  @override
  String get officerStatus => 'Statut de l\'officier';
  @override
  String get goOnline => 'Aller en ligne';
  @override
  String get goOffline => 'Aller hors ligne';
  @override
  String get zoneCode => 'Code de zone';
  @override
  String get full => 'Plein';
  @override
  String get occupied => 'Occupé';
  @override
  String get available => 'Disponible';
  @override
  String get total => 'Total';
}

class _SpanishLocalizations extends AppLocalizations {
  @override
  String get appTitle => 'Space Officer';
  @override
  String get zones => 'Zonas';
  @override
  String get scan => 'Escanear';
  @override
  String get search => 'Buscar';
  @override
  String get chat => 'Chat';
  @override
  String get history => 'Historia';
  @override
  String get profile => 'Perfil';
  @override
  String get logout => 'Cerrar Sesión';
  @override
  String get zoneMonitor => 'Monitor de Zona';
  @override
  String get dailyScans => 'Escaneos Diarios';
  @override
  String get dailyViolations => 'Violaciones';
  @override
  String get online => 'EN LÍNEA';
  @override
  String get offline => 'FUERA DE LÍNEA';
  @override
  String get activeZones => 'Zonas Activas';
  @override
  String get refresh => 'Refrescar';
  @override
  String get noActiveZones => 'No se encontraron zonas activas.';
  @override
  String get officerStatus => 'Estado del Oficial';
  @override
  String get goOnline => 'Ponerse en línea';
  @override
  String get goOffline => 'Salir de línea';
  @override
  String get zoneCode => 'Código de zona';
  @override
  String get full => 'Lleno';
  @override
  String get occupied => 'Ocupado';
  @override
  String get available => 'Disponible';
  @override
  String get total => 'Total';
}

// German Localizations
class _GermanLocalizations extends AppLocalizations {
  @override
  String get appTitle => 'Space Officer';
  @override
  String get zones => 'Zonen';
  @override
  String get scan => 'Scannen';
  @override
  String get search => 'Suchen';
  @override
  String get chat => 'Chat';
  @override
  String get history => 'Verlauf';
  @override
  String get profile => 'Profil';
  @override
  String get logout => 'Abmelden';
  @override
  String get zoneMonitor => 'Zonen-Monitor';
  @override
  String get dailyScans => 'Tägliche Scans';
  @override
  String get dailyViolations => 'Verstöße';
  @override
  String get online => 'ONLINE';
  @override
  String get offline => 'OFFLINE';
  @override
  String get activeZones => 'Aktive Zonen';
  @override
  String get refresh => 'Aktualisieren';
  @override
  String get noActiveZones => 'Keine aktiven Zonen gefunden.';
  @override
  String get officerStatus => 'Offiziersstatus';
  @override
  String get goOnline => 'Online gehen';
  @override
  String get goOffline => 'Offline gehen';
  @override
  String get zoneCode => 'Zonencode';
  @override
  String get full => 'Voll';
  @override
  String get occupied => 'Besetzt';
  @override
  String get available => 'Verfügbar';
  @override
  String get total => 'Gesamt';
}

// Arabic Localizations
class _ArabicLocalizations extends AppLocalizations {
  @override
  String get appTitle => 'Space Officer';
  @override
  String get zones => 'المناطق';
  @override
  String get scan => 'مسح';
  @override
  String get search => 'بحث';
  @override
  String get chat => 'محادثة';
  @override
  String get history => 'السجل';
  @override
  String get profile => 'الملف الشخصي';
  @override
  String get logout => 'تسجيل الخروج';
  @override
  String get zoneMonitor => 'مراقب المنطقة';
  @override
  String get dailyScans => 'المسحات اليومية';
  @override
  String get dailyViolations => 'المخالفات';
  @override
  String get online => 'متصل';
  @override
  String get offline => 'غير متصل';
  @override
  String get activeZones => 'المناطق النشطة';
  @override
  String get refresh => 'تحديث';
  @override
  String get noActiveZones => 'لم يتم العثور على مناطق نشطة.';
  @override
  String get officerStatus => 'حالة الضابط';
  @override
  String get goOnline => 'اتصال';
  @override
  String get goOffline => 'قطع الاتصال';
  @override
  String get zoneCode => 'رمز المنطقة';
  @override
  String get full => 'ممتلئ';
  @override
  String get occupied => 'مشغول';
  @override
  String get available => 'متاح';
  @override
  String get total => 'الإجمالي';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['en', 'sw', 'fr', 'es', 'de', 'ar'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
