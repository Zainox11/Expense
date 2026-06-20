import 'package:hive/hive.dart';
import 'package:expense_tracker/data/models/budget_model.dart';

/// Local datasource for budgets backed by a Hive box.
class HiveBudgetDatasource {
  static const String boxName = 'budgets';

  final Box<BudgetModel> _box;

  HiveBudgetDatasource(this._box);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Returns all budgets for [userId].
  List<BudgetModel> getAll(String userId) {
    return _box.values
        .where((b) => b.userId == userId)
        .toList()
      ..sort((a, b) {
        // Sort by year desc, then month desc
        final yearCmp = b.year.compareTo(a.year);
        return yearCmp != 0 ? yearCmp : b.month.compareTo(a.month);
      });
  }

  /// Returns a single budget by [id], or `null` if not found.
  BudgetModel? getById(String id) {
    try {
      return _box.values.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new budget entry.
  Future<void> add(BudgetModel model) async {
    await _box.put(model.id, model);
  }

  /// Updates an existing budget entry.
  Future<void> update(BudgetModel model) async {
    await _box.put(model.id, model);
  }

  /// Deletes the budget with the given [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns all budgets for [userId] in a specific [month] and [year].
  List<BudgetModel> getByMonth(String userId, int month, int year) {
    return _box.values
        .where((b) =>
            b.userId == userId && b.month == month && b.year == year)
        .toList();
  }

  /// Returns the budget for a specific [categoryId] in a given [month]/[year].
  BudgetModel? getByCategoryAndMonth(
    String userId,
    String categoryId,
    int month,
    int year,
  ) {
    try {
      return _box.values.firstWhere((b) =>
          b.userId == userId &&
          b.categoryId == categoryId &&
          b.month == month &&
          b.year == year);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Bulk operations
  // ---------------------------------------------------------------------------

  /// Replaces all local budgets for [userId] with [models].
  Future<void> replaceAll(String userId, List<BudgetModel> models) async {
    final keysToRemove = _box.keys
        .where((key) {
          final item = _box.get(key);
          return item != null && item.userId == userId;
        })
        .toList();
    await _box.deleteAll(keysToRemove);

    final entries = {for (final m in models) m.id: m};
    await _box.putAll(entries);
  }

  /// Exposes the underlying box for watching changes.
  Box<BudgetModel> get box => _box;
}
