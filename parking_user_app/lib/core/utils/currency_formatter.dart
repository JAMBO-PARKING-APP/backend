import 'package:intl/intl.dart';
import 'package:parking_user_app/core/models/country_config.dart';

class CurrencyFormatter {
  /// Format amount with country-specific currency and conversion
  static String formatCurrency(double amount, CountryConfig config) {
    final converted = amount * config.exchangeRate;
    final formatter = NumberFormat.currency(
      symbol: config.currencySymbol,
      decimalDigits: 0, // Most African currencies don't use decimal places
    );
    return formatter.format(converted);
  }

  /// Format amount without currency symbol
  static String formatAmount(double amount, CountryConfig config) {
    final converted = amount * config.exchangeRate;
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(converted);
  }

  /// Get currency symbol only
  static String getCurrencySymbol(CountryConfig config) {
    return config.currencySymbol;
  }

  /// Format with custom decimal places
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
