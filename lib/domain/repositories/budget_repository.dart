import 'package:expense_tracker/domain/entities/budget_entity.dart';

/// Abstract repository interface for budget operations.
/// Implemented by the data layer; consumed by use cases.
abstract class BudgetRepository {
  /// Fetches all budgets for a user for a specific month and year.
  Future<List<BudgetEntity>> getBudgetsByMonth(
    String userId,
    int month,
    int year,
  );

  /// Fetches a single budget by its ID.
  Future<BudgetEntity?> getBudgetById(String id);

  /// Adds or updates a budget (upsert).
  /// If a budget for the same category/month/year exists, it updates it.
  Future<void> setBudget(BudgetEntity budget);

  /// Updates an existing budget.
  Future<void> updateBudget(BudgetEntity budget);

  /// Deletes a budget by its ID.
  Future<void> deleteBudget(String id);

  /// Updates the spent amount for a budget.
  /// Called when transactions change to keep budgets in sync.
  Future<void> updateSpentAmount(
    String userId,
    String categoryId,
    int month,
    int year,
    double spentAmount,
  );
}
