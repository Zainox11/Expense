import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:expense_tracker/domain/entities/transaction_entity.dart';

/// Service for processing recurring transactions using a calculate-on-launch
/// pattern.
///
/// On every app launch (or periodic check), this service scans all recurring
/// transactions and generates any missing instances between the last occurrence
/// date and the current date.
///
/// Usage:
/// ```dart
/// final service = RecurringTransactionService();
/// final newTxs = service.processRecurringTransactions(
///   userId: 'user_123',
///   transactions: allTransactions,
/// );
/// // Persist newTxs to your datasource
/// ```
class RecurringTransactionService {
  RecurringTransactionService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  // ---------------------------------------------------------------------------
  // Core Processing
  // ---------------------------------------------------------------------------

  /// Scan all [transactions] for recurring ones and generate any missing
  /// occurrences up to today.
  ///
  /// Returns a list of newly generated [TransactionEntity] objects that should
  /// be persisted by the caller.
  ///
  /// Only processes transactions belonging to [userId] and whose
  /// `recurrence != RecurrenceType.none`.
  List<TransactionEntity> processRecurringTransactions({
    required String userId,
    required List<TransactionEntity> transactions,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final newTransactions = <TransactionEntity>[];

    // Filter to only recurring transactions for this user
    final recurringTxs = transactions.where(
      (t) => t.userId == userId && t.recurrence != RecurrenceType.none,
    );

    for (final template in recurringTxs) {
      final generated = _generateMissingOccurrences(
        template: template,
        upToDate: today,
        existingTransactions: transactions,
      );
      newTransactions.addAll(generated);
    }

    if (newTransactions.isNotEmpty) {
      debugPrint(
        'RecurringTransactionService: Generated ${newTransactions.length} '
        'new transactions from ${recurringTxs.length} recurring templates',
      );
    }

    return newTransactions;
  }

  /// Generate all missing transaction instances between the template's last
  /// known date and [upToDate].
  ///
  /// Uses the set of [existingTransactions] to avoid creating duplicates by
  /// checking if a transaction with the same categoryId, amount, and date
  /// already exists.
  List<TransactionEntity> _generateMissingOccurrences({
    required TransactionEntity template,
    required DateTime upToDate,
    required List<TransactionEntity> existingTransactions,
  }) {
    final generated = <TransactionEntity>[];

    // Build a set of existing (categoryId, date) pairs for quick duplicate check
    final existingKeys = <String>{};
    for (final tx in existingTransactions) {
      final dateKey = _dateKey(tx.date);
      existingKeys.add('${tx.categoryId}_${tx.amount}_$dateKey');
    }

    // Start generating from the day after the template's original date
    DateTime nextDate = getNextOccurrence(
      date: template.date,
      recurrenceType: template.recurrence,
    );

    // Safety limit to prevent infinite loops (max 366 iterations = 1 year of daily)
    int safetyCounter = 0;
    const maxIterations = 366;

    while (!nextDate.isAfter(upToDate) && safetyCounter < maxIterations) {
      safetyCounter++;

      final key =
          '${template.categoryId}_${template.amount}_${_dateKey(nextDate)}';

      // Only generate if this occurrence doesn't already exist
      if (!existingKeys.contains(key)) {
        final newTx = TransactionEntity(
          id: _uuid.v4(),
          userId: template.userId,
          amount: template.amount,
          type: template.type,
          categoryId: template.categoryId,
          note: template.note.isEmpty
              ? 'Recurring'
              : '${template.note} (Recurring)',
          date: nextDate,
          createdAt: DateTime.now(),
          recurrence: RecurrenceType.none, // Generated instances are one-off
          isSynced: false,
        );
        generated.add(newTx);
        existingKeys.add(key); // Prevent duplicates within this batch
      }

      nextDate = getNextOccurrence(
        date: nextDate,
        recurrenceType: template.recurrence,
      );
    }

    return generated;
  }

  // ---------------------------------------------------------------------------
  // Date Calculation
  // ---------------------------------------------------------------------------

  /// Calculate the next occurrence date from the given [date] based on
  /// [recurrenceType].
  ///
  /// - **daily**: next day
  /// - **weekly**: +7 days
  /// - **monthly**: same day next month (clamped to month-end if needed)
  /// - **yearly**: same day next year (handles Feb 29 → Feb 28)
  /// - **none**: returns the same date (no recurrence)
  DateTime getNextOccurrence({
    required DateTime date,
    required RecurrenceType recurrenceType,
  }) {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        return DateTime(date.year, date.month, date.day + 1);

      case RecurrenceType.weekly:
        return DateTime(date.year, date.month, date.day + 7);

      case RecurrenceType.monthly:
        return _addMonths(date, 1);

      case RecurrenceType.yearly:
        return _addYears(date, 1);

      case RecurrenceType.none:
        return date;
    }
  }

  /// Add [months] to a date, clamping the day to the last valid day of the
  /// target month.
  ///
  /// Example: Jan 31 + 1 month = Feb 28 (or 29 in a leap year).
  DateTime _addMonths(DateTime date, int months) {
    int newMonth = date.month + months;
    int newYear = date.year;

    // Handle year rollover
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }

    // Clamp day to the last day of the target month
    final lastDayOfMonth = DateTime(newYear, newMonth + 1, 0).day;
    final clampedDay = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;

    return DateTime(newYear, newMonth, clampedDay);
  }

  /// Add [years] to a date, handling leap year edge cases (Feb 29 → Feb 28).
  DateTime _addYears(DateTime date, int years) {
    final newYear = date.year + years;
    final lastDayOfMonth = DateTime(newYear, date.month + 1, 0).day;
    final clampedDay = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;

    return DateTime(newYear, date.month, clampedDay);
  }

  // ---------------------------------------------------------------------------
  // Query Helpers
  // ---------------------------------------------------------------------------

  /// Check if a recurring [transaction] is due (i.e., its next occurrence is
  /// today or in the past).
  ///
  /// Returns `false` for non-recurring transactions.
  bool isDue(TransactionEntity transaction) {
    if (transaction.recurrence == RecurrenceType.none) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDate = getNextOccurrence(
      date: transaction.date,
      recurrenceType: transaction.recurrence,
    );

    return !nextDate.isAfter(today); // Due if nextDate <= today
  }

  /// Get all recurring transactions that are currently due.
  ///
  /// Filters the [transactions] list to only include recurring ones belonging
  /// to [userId] where [isDue] returns `true`.
  List<TransactionEntity> getDueTransactions({
    required String userId,
    required List<TransactionEntity> transactions,
  }) {
    return transactions
        .where(
          (t) =>
              t.userId == userId &&
              t.recurrence != RecurrenceType.none &&
              isDue(t),
        )
        .toList();
  }

  /// Get a human-readable label for the recurrence frequency.
  static String recurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return 'One-time';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Create a normalized date key string for deduplication.
  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
