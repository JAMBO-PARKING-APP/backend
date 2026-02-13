class Country {
  final String id;
  final String name;
  final String isoCode;
  final String currency;
  final String currencySymbol;
  final String timezone;
  final String phoneCode;
  final String? flagEmoji;

  Country({
    required this.id,
    required this.name,
    required this.isoCode,
    required this.currency,
    required this.currencySymbol,
    required this.timezone,
    required this.phoneCode,
    this.flagEmoji,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isoCode: json['iso_code'] ?? '',
      currency: json['currency'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '',
      timezone: json['timezone'] ?? '',
      phoneCode: json['phone_code'] ?? '',
      flagEmoji: json['flag_emoji'],
    );
  }
}
