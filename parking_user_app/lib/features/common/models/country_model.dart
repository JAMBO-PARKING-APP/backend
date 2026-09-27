class Country {
  final String id;
  final String name;
  final String code;
  final String currency;
  final String currencySymbol;
  final String phoneCode;
  final String flag;
  final bool isActive;

  const Country({
    required this.id,
    required this.name,
    required this.code,
    required this.currency,
    required this.currencySymbol,
    required this.phoneCode,
    required this.flag,
    this.isActive = true,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    code: (json['iso_code'] ?? json['code'] ?? '').toString(),
    currency: json['currency']?.toString() ?? 'UGX',
    currencySymbol: (json['currency_symbol'] ?? json['currency'] ?? 'UGX')
        .toString(),
    phoneCode: json['phone_code']?.toString() ?? '',
    flag: (json['flag_emoji'] ?? json['flag'] ?? '').toString(),
    isActive: json['is_active'] != false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iso_code': code,
    'currency': currency,
    'currency_symbol': currencySymbol,
    'phone_code': phoneCode,
    'flag_emoji': flag,
    'is_active': isActive,
  };
}
