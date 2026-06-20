import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Useful extensions on common Dart and Flutter types.

// ──────────────────────────────────────────────
// String Extensions
// ──────────────────────────────────────────────

extension StringExtensions on String {
  /// Capitalizes the first letter: "hello" → "Hello"
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes each word: "hello world" → "Hello World"
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Returns the initials from a name: "John Doe" → "JD"
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  /// Truncates string with ellipsis: "Hello World" → "Hello..."
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Returns true if the string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(this);
  }

  /// Returns true if the string can be parsed as a number
  bool get isNumeric => double.tryParse(this) != null;

  /// Parses the string as a double, returns null if invalid
  double? toDoubleOrNull() => double.tryParse(this);
}

// ──────────────────────────────────────────────
// DateTime Extensions
// ──────────────────────────────────────────────

extension DateTimeExtensions on DateTime {
  /// Returns true if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns true if this date is in the current month
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Returns true if this date is in the current year
  bool get isThisYear => year == DateTime.now().year;

  /// Formats as "Jan 15, 2025"
  String get formatted => DateFormat('MMM dd, yyyy').format(this);

  /// Formats as "Jan 15"
  String get shortFormatted => DateFormat('MMM dd').format(this);

  /// Formats as "02:30 PM"
  String get timeFormatted => DateFormat('hh:mm a').format(this);

  /// Formats as "January 2025"
  String get monthFormatted => DateFormat('MMMM yyyy').format(this);

  /// Returns "Today", "Yesterday", or formatted date
  String get relativeFormat {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isThisYear) return shortFormatted;
    return formatted;
  }

  /// Returns a new DateTime with only the date component (midnight)
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns the start of the month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Returns the end of the month (last moment of last day)
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);

  /// Returns true if this date is the same calendar day as [other]
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns the number of days in this date's month
  int get daysInMonth => DateTime(year, month + 1, 0).day;
}

// ──────────────────────────────────────────────
// Double Extensions
// ──────────────────────────────────────────────

extension DoubleExtensions on double {
  /// Formats as currency with symbol: "$1,234.56"
  String toCurrency({String symbol = '\$'}) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(this);
  }

  /// Formats as currency without decimals: "$1,235"
  String toCurrencyWhole({String symbol = '\$'}) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 0).format(this);
  }

  /// Formats as compact currency: "$1.2K"
  String toCompactCurrency({String symbol = '\$'}) {
    if (abs() >= 1e9) return '$symbol${(this / 1e9).toStringAsFixed(1)}B';
    if (abs() >= 1e6) return '$symbol${(this / 1e6).toStringAsFixed(1)}M';
    if (abs() >= 1e3) return '$symbol${(this / 1e3).toStringAsFixed(1)}K';
    return toCurrency(symbol: symbol);
  }

  /// Formats with sign: "+$500.00" or "-$200.00"
  String toSignedCurrency({String symbol = '\$'}) {
    final prefix = this >= 0 ? '+' : '';
    return '$prefix${toCurrency(symbol: symbol)}';
  }

  /// Formats as percentage: "75.5%"
  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Clamps value between 0 and 1 for progress indicators
  double get clampProgress => clamp(0.0, 1.0) as double;
}

// ──────────────────────────────────────────────
// BuildContext Extensions
// ──────────────────────────────────────────────

extension BuildContextExtensions on BuildContext {
  /// Access the current ThemeData
  ThemeData get theme => Theme.of(this);

  /// Access the current ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Access the current TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Access the current MediaQuery data
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Whether the current theme is dark
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Shows a snackbar with the given message
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : null,
      ),
    );
  }

  /// Shows a success snackbar
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF00E676),
      ),
    );
  }

  /// Unfocuses current focus (dismisses keyboard)
  void unfocus() => FocusScope.of(this).unfocus();
}

// ──────────────────────────────────────────────
// List Extensions
// ──────────────────────────────────────────────

extension ListExtensions<T> on List<T> {
  /// Returns the list sorted by a comparable property without mutating
  List<T> sortedBy<R extends Comparable>(R Function(T element) selector) {
    final copy = List<T>.from(this);
    copy.sort((a, b) => selector(a).compareTo(selector(b)));
    return copy;
  }

  /// Returns the list sorted in descending order by a comparable property
  List<T> sortedByDescending<R extends Comparable>(R Function(T element) selector) {
    final copy = List<T>.from(this);
    copy.sort((a, b) => selector(b).compareTo(selector(a)));
    return copy;
  }

  /// Groups list elements by a key
  Map<K, List<T>> groupBy<K>(K Function(T element) keySelector) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keySelector(element);
      map.putIfAbsent(key, () => []).add(element);
    }
    return map;
  }

  /// Returns the sum of a numeric property
  double sumBy(double Function(T element) selector) {
    return fold(0.0, (sum, element) => sum + selector(element));
  }
}
