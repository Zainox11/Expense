import 'package:intl/intl.dart';

/// Currency formatting utility.
/// Handles formatting with symbols and compact notation for large numbers.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Default currency symbol (can be changed via settings)
  static String _currencySymbol = '\$';
  static String _currencyCode = 'USD';

  /// Update the active currency
  static void setCurrency({required String symbol, required String code}) {
    _currencySymbol = symbol;
    _currencyCode = code;
  }

  /// Current currency symbol
  static String get symbol => _currencySymbol;

  /// Current currency code
  static String get code => _currencyCode;

  // ──────────────────────────────────────────────
  // Formatting Methods
  // ──────────────────────────────────────────────

  /// Formats amount with currency symbol: "$1,234.56"
  static String format(double amount, {String? symbol}) {
    final formatter = NumberFormat.currency(
      symbol: symbol ?? _currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Formats amount without decimal places: "$1,235"
  static String formatWhole(double amount, {String? symbol}) {
    final formatter = NumberFormat.currency(
      symbol: symbol ?? _currencySymbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Formats with compact notation for large numbers:
  /// "$1.2K", "$3.5M", "$7.8B"
  static String formatCompact(double amount, {String? symbol}) {
    final sym = symbol ?? _currencySymbol;
    if (amount.abs() >= 1e9) {
      return '$sym${(amount / 1e9).toStringAsFixed(1)}B';
    } else if (amount.abs() >= 1e6) {
      return '$sym${(amount / 1e6).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1e3) {
      return '$sym${(amount / 1e3).toStringAsFixed(1)}K';
    }
    return format(amount, symbol: sym);
  }

  /// Formats amount with sign: "+$500.00" or "-$200.00"
  static String formatWithSign(double amount, {String? symbol}) {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix${format(amount, symbol: symbol)}';
  }

  /// Formats amount without currency symbol: "1,234.56"
  static String formatPlain(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  /// Formats just the integer part for display: "1,234"
  static String formatIntegerPart(double amount) {
    final formatter = NumberFormat('#,##0');
    return formatter.format(amount.truncate());
  }

  /// Returns the decimal part as a string: ".56"
  static String getDecimalPart(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    return '.${parts.length > 1 ? parts[1] : "00"}';
  }

  /// Parses a formatted currency string back to double.
  /// Handles commas, currency symbols, and whitespace.
  static double? parse(String value) {
    try {
      // Remove currency symbols, commas, and whitespace
      final cleaned = value
          .replaceAll(_currencySymbol, '')
          .replaceAll(',', '')
          .replaceAll(' ', '')
          .trim();
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // Supported Currencies
  // ──────────────────────────────────────────────

  /// List of common currencies for the settings picker
  static const List<({String code, String symbol, String name})> supportedCurrencies = [
    (code: 'USD', symbol: '\$', name: 'US Dollar'),
    (code: 'EUR', symbol: '€', name: 'Euro'),
    (code: 'GBP', symbol: '£', name: 'British Pound'),
    (code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    (code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
    (code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    (code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    (code: 'PKR', symbol: 'Rs', name: 'Pakistani Rupee'),
    (code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    (code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    (code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    (code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    (code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    (code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    (code: 'TRY', symbol: '₺', name: 'Turkish Lira'),
  ];
}
