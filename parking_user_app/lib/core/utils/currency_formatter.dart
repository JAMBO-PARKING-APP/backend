import 'package:intl/intl.dart';
import 'package:parking_user_app/core/models/country_config.dart';

class CurrencyFormatter {
  static String formatCurrency(double amount, CountryConfig config) {
    final converted = amount * config.exchangeRate;
    final formatter = NumberFormat.currency(
      symbol: config.currencySymbol,
      decimalDigits: 0, 
    );
    return formatter.format(converted);
  }

  static String formatAmount(double amount, CountryConfig config) {
    final converted = amount * config.exchangeRate;
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(converted);
  }

  static String getCurrencySymbol(CountryConfig config) {
    return config.currencySymbol;
  }

  static String formatCurrencyWithDecimals(
    double amount,
    CountryConfig config, {
    int decimalPlaces = 2,
  }) {
    final converted = amount * config.exchangeRate;
    final formatter = NumberFormat.currency(
      symbol: config.currencySymbol,
      decimalDigits: decimalPlaces,
    );
    return formatter.format(converted);
  }
}
