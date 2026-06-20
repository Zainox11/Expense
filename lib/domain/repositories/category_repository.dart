import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';

/// Abstract repository interface for category operations.
/// Implemented by the data layer; consumed by use cases.
abstract class CategoryRepository {
  /// Fetches all categories, optionally filtered by transaction type.
  Future<List<CategoryEntity>> getCategories({TransactionType? type});

  /// Fetches a single category by its ID.
  Future<CategoryEntity?> getCategoryById(String id);

  /// Adds a new category.
  Future<void> addCategory(CategoryEntity category);

  /// Updates an existing category.
  Future<void> updateCategory(CategoryEntity category);

  /// Deletes a category by its ID.
  /// Should only allow deletion of non-default categories.
  Future<void> deleteCategory(String id);

  /// Seeds the database with default categories if none exist.
  Future<void> seedDefaultCategories();
}
