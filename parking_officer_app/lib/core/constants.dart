import 'dart:io' show Platform;

class AppConstants {
  static bool useProduction = true;
  static const String prodBase = 'https://backend.p-space.ai/api/';

  static String get baseUrl {
    if (useProduction) return prodBase;
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:8000/api/';
  }

  static String get wsUrl {
    final base = baseUrl;
    final wsScheme = base.startsWith('https') ? 'wss' : 'ws';
    final cleanBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return cleanBase
        .replaceFirst(RegExp(r'https?'), wsScheme)
        .replaceFirst('/api', '/ws');
  }

  static const String appName = 'Space Officer';
}

class CountryCode {
  final String name;
  final String code;
  final String flag;
  final String dialCode;

  CountryCode({
    required this.name,
    required this.code,
    required this.flag,
    required this.dialCode,
  });
}

final List<CountryCode> countryCodes = [
  CountryCode(name: 'Kenya', code: 'KE', flag: '🇰🇪', dialCode: '+254'),
  CountryCode(name: 'Uganda', code: 'UG', flag: '🇺🇬', dialCode: '+256'),
  CountryCode(name: 'Tanzania', code: 'TZ', flag: '🇹🇿', dialCode: '+255'),
  CountryCode(name: 'Rwanda', code: 'RW', flag: '🇷🇼', dialCode: '+250'),
  CountryCode(name: 'Nigeria', code: 'NG', flag: '🇳🇬', dialCode: '+234'),
  CountryCode(name: 'South Africa', code: 'ZA', flag: '🇿🇦', dialCode: '+27'),
  CountryCode(name: 'Ghana', code: 'GH', flag: '🇬🇭', dialCode: '+233'),
  CountryCode(name: 'Ethiopia', code: 'ET', flag: '🇪🇹', dialCode: '+251'),
  CountryCode(name: 'Cameroon', code: 'CM', flag: '🇨🇲', dialCode: '+237'),
  CountryCode(name: 'Botswana', code: 'BW', flag: '🇧🇼', dialCode: '+267'),
];
