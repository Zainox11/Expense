import 'package:intl/intl.dart';

/// Date formatting and utility helpers.
/// Centralizes all date operations for consistency across the app.
class AppDateUtils {
  AppDateUtils._();

  // ──────────────────────────────────────────────
  // Formatters
  // ──────────────────────────────────────────────

  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM dd');
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonthFormat = DateFormat('MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dayFormat = DateFormat('EEE');
  static final DateFormat _fullFormat = DateFormat('EEEE, MMM dd, yyyy');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  // ──────────────────────────────────────────────
  // Format Methods
  // ──────────────────────────────────────────────

  /// Formats date as "Jan 15, 2025"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Formats date as "Jan 15"
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  /// Formats date as "January 2025"
  static String formatMonth(DateTime date) => _monthFormat.format(date);

  /// Formats date as "Jan 2025"
  static String formatShortMonth(DateTime date) => _shortMonthFormat.format(date);

  /// Formats time as "02:30 PM"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Formats date as "Mon"
  static String formatDay(DateTime date) => _dayFormat.format(date);

  /// Formats date as "Monday, Jan 15, 2025"
  static String formatFull(DateTime date) => _fullFormat.format(date);

  /// Formats date as "2025-01-15" (ISO 8601)
  static String formatIso(DateTime date) => _isoFormat.format(date);

  /// Formats a date relative to today: "Today", "Yesterday", or "Jan 15"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return formatDay(date);
    return formatShortDate(date);
  }

  // ──────────────────────────────────────────────
  // Month Helpers
  // ──────────────────────────────────────────────

  /// Returns the full month name for a given month number (1-12)
  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  /// Returns the short month name (3 letters) for a month number (1-12)
  static String getShortMonthName(int month) {
    return getMonthName(month).substring(0, 3);
  }

  /// Returns the number of days in a given month and year
  static int getDaysInMonth(int year, int month) {
    // Using the day-0-of-next-month trick
    return DateTime(year, month + 1, 0).day;
  }

  // ──────────────────────────────────────────────
  // Date Checks
  // ──────────────────────────────────────────────

  /// Returns true if the given date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Returns true if the given date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Returns true if the given date is in the current month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Returns true if the given date is in the current year
  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  /// Returns true if two dates are the same calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ──────────────────────────────────────────────
  // Date Range Helpers
  // ──────────────────────────────────────────────

  /// Returns the start and end of a given month
  static ({DateTime start, DateTime end}) getMonthRange(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return (start: start, end: end);
  }

  /// Returns the start and end of the current week (Monday-Sunday)
  static ({DateTime start, DateTime end}) getCurrentWeekRange() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return (start: start, end: end);
  }

  /// Returns a date range for predefined periods
  static ({DateTime start, DateTime end}) getDateRange(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case 'today':
        return (
          start: today,
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'this_week':
        return getCurrentWeekRange();
      case 'this_month':
        return getMonthRange(now.year, now.month);
      case 'this_year':
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case 'last_30_days':
        return (
          start: today.subtract(const Duration(days: 30)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'last_90_days':
        return (
          start: today.subtract(const Duration(days: 90)),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      default:
        return getMonthRange(now.year, now.month);
    }
  }

  /// Returns a list of all dates between start and end (inclusive)
  static List<DateTime> getDatesBetween(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDate)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  /// Strips time component, returning midnight of the same day
  static DateTime stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
