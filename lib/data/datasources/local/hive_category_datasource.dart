import 'package:hive/hive.dart';
import 'package:expense_tracker/data/models/category_model.dart';

/// Local datasource for categories backed by a Hive box.
class HiveCategoryDatasource {
  static const String boxName = 'categories';

  final Box<CategoryModel> _box;

  HiveCategoryDatasource(this._box);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Returns all categories, sorted alphabetically by name.
  List<CategoryModel> getAll() {
    return _box.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Returns categories filtered by transaction type (0 = income, 1 = expense).
  List<CategoryModel> getByType(int type) {
    return _box.values
        .where((c) => c.type == type)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Returns a single category by [id], or `null` if not found.
  CategoryModel? getById(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new category to the box.
  Future<void> add(CategoryModel model) async {
    await _box.put(model.id, model);
  }

  /// Updates an existing category.
  Future<void> update(CategoryModel model) async {
    await _box.put(model.id, model);
  }

  /// Deletes the category with the given [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns all default (built-in) categories.
  List<CategoryModel> getDefaults() {
    return _box.values.where((c) => c.isDefault).toList();
  }

  // ---------------------------------------------------------------------------
  // Bulk operations
  // ---------------------------------------------------------------------------

  /// Replaces all local categories with [models].
  Future<void> replaceAll(List<CategoryModel> models) async {
    await _box.clear();
    final entries = {for (final m in models) m.id: m};
    await _box.putAll(entries);
  }

  /// Exposes the underlying box for watching changes.
  Box<CategoryModel> get box => _box;
}
