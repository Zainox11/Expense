import 'package:expense_tracker/domain/entities/transaction_entity.dart';

/// Abstract repository interface for transaction operations.
/// Implemented by the data layer; consumed by use cases.
abstract class TransactionRepository {
  /// Fetches all transactions for a user, optionally filtered by date range.
  Future<List<TransactionEntity>> getTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Adds a new transaction.
  Future<void> addTransaction(TransactionEntity transaction);

  /// Updates an existing transaction.
  Future<void> updateTransaction(TransactionEntity transaction);

  /// Deletes a transaction by its ID.
  Future<void> deleteTransaction(String id);

  /// Returns a real-time stream of transactions for a user.
  /// Useful for reactive UI updates when data changes.
  Stream<List<TransactionEntity>> watchTransactions(String userId);

  /// Calculates total income for a specific month and year.
  Future<double> getTotalIncome(String userId, int month, int year);

  /// Calculates total expenses for a specific month and year.
  Future<double> getTotalExpense(String userId, int month, int year);
}
