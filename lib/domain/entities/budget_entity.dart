/// Core domain entity representing a monthly budget for a category.
/// Tracks the budget limit and current spending for a given month/year.
class BudgetEntity {
  final String id;
  final String userId;
  final String categoryId;
  final double amount; // Budget limit
  final double spent; // Current spending against this budget
  final int month; // 1-12
  final int year; // e.g., 2025

  const BudgetEntity({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    this.spent = 0.0,
    required this.month,
    required this.year,
  });

  /// Percentage of budget used (0.0 to 1.0+)
  /// Can exceed 1.0 when over budget
  double get percentUsed {
    if (amount <= 0) return 0.0;
    return spent / amount;
  }

  /// Percentage clamped to 0–100 for progress bars
  double get percentUsedClamped => percentUsed.clamp(0.0, 1.0);

  /// Remaining budget amount (negative if over budget)
  double get remaining => amount - spent;

  /// Whether spending has exceeded the budget
  bool get isOverBudget => spent > amount;

  /// Whether spending is at or above 80% of the budget (warning threshold)
  bool get isNearLimit => percentUsed >= 0.8 && !isOverBudget;

  /// Creates a copy with the given fields replaced
  BudgetEntity copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    double? spent,
    int? month,
    int? year,
  }) {
    return BudgetEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          categoryId == other.categoryId &&
          amount == other.amount &&
          spent == other.spent &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode =>
      Object.hash(id, userId, categoryId, amount, spent, month, year);

  @override
  String toString() {
    return 'BudgetEntity(id: $id, categoryId: $categoryId, '
        'amount: $amount, spent: $spent, '
        'month: $month/$year, percentUsed: ${(percentUsed * 100).toStringAsFixed(1)}%)';
  }
}
