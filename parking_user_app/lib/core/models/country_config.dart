class CountryConfig {
  final String countryCode;
  final String countryName;
  final String currencyCode;
  final String currencySymbol;
  final List<String> paymentMethods;
  final double exchangeRate;

  CountryConfig({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.paymentMethods,
    required this.exchangeRate,
  });

  factory CountryConfig.fromJson(Map<String, dynamic> json) {
    return CountryConfig(
      countryCode: json['country_code'] as String,
      countryName: json['country_name'] as String,
      currencyCode: json['currency_code'] as String,
      currencySymbol: json['currency_symbol'] as String,
      paymentMethods: List<String>.from(json['payment_methods'] as List),
      exchangeRate: double.parse(json['exchange_rate'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country_code': countryCode,
      'country_name': countryName,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'payment_methods': paymentMethods,
      'exchange_rate': exchangeRate,
    };
  }

  // Default configuration for fallback
  static CountryConfig get defaultConfig => CountryConfig(
    countryCode: 'UG',
    countryName: 'Uganda',
    currencyCode: 'UGX',
    currencySymbol: 'UGX',
    paymentMethods: ['wallet', 'pesapal'],
    exchangeRate: 1.0,
  );
}
