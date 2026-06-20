import 'dart:async';

import 'package:expense_tracker/core/network/connectivity_service.dart';
import 'package:expense_tracker/data/datasources/local/hive_category_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_category_datasource.dart';
import 'package:expense_tracker/data/models/category_model.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/repositories/category_repository.dart';

/// Offline-first implementation of [CategoryRepository].
///
/// Categories are not user-scoped for local storage (they're shared), but
/// Firestore stores them under `users/{userId}/categories` for per-user
/// customization.
class CategoryRepositoryImpl implements CategoryRepository {
  final HiveCategoryDatasource _localDatasource;
  final FirebaseCategoryDatasource _remoteDatasource;
  final ConnectivityService _connectivity;

  CategoryRepositoryImpl({
    required HiveCategoryDatasource localDatasource,
    required FirebaseCategoryDatasource remoteDatasource,
    required ConnectivityService connectivity,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource,
        _connectivity = connectivity;

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  @override
  Future<List<CategoryEntity>> getCategories({TransactionType? type}) async {
    if (type != null) {
      return getCategoriesByType(type);
    }
    final localModels = _localDatasource.getAll();
    return localModels.map((m) => m.toEntity()).toList();
  }

  Future<List<CategoryEntity>> getCategoriesByType(
      TransactionType type) async {
    final typeInt = type == TransactionType.income ? 0 : 1;
    final models = _localDatasource.getByType(typeInt);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) async {
    final model = _localDatasource.getById(id);
    return model?.toEntity();
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  @override
  Future<void> addCategory(CategoryEntity entity) async {
    final model = CategoryModel.fromEntity(entity);
    await _localDatasource.add(model);
  }

  @override
  Future<void> updateCategory(CategoryEntity entity) async {
    final model = CategoryModel.fromEntity(entity);
    await _localDatasource.update(model);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _localDatasource.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  Stream<List<CategoryEntity>> watchCategories() {
    return _localDatasource.box
        .watch()
        .map((_) =>
            _localDatasource.getAll().map((m) => m.toEntity()).toList());
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  Future<void> syncCategories(String userId) async {
    if (!await _connectivity.isConnected) return;

    try {
      // Push all local categories to remote
      final localModels = _localDatasource.getAll();
      if (localModels.isNotEmpty) {
        await _remoteDatasource.syncBatch(userId, localModels);
      }

      // Pull remote categories into local
      final remoteModels = await _remoteDatasource.getAll(userId);
      await _localDatasource.replaceAll(remoteModels);
    } catch (_) {
      // Non-critical — we continue with local data
    }
  }

  Future<List<CategoryEntity>> getDefaultCategories() async {
    final models = _localDatasource.getDefaults();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> seedDefaultCategories() async {
    final existing = _localDatasource.getAll();
    if (existing.isEmpty) {
      final defaults = [
        CategoryModel(id: 'food', name: 'Food & Dining', iconCode: 0xe55a, colorValue: 0xFFFF7043, type: 1, isDefault: true),
        CategoryModel(id: 'transport', name: 'Transportation', iconCode: 0xe1d1, colorValue: 0xFF42A5F5, type: 1, isDefault: true),
        CategoryModel(id: 'shopping', name: 'Shopping', iconCode: 0xe59c, colorValue: 0xFFAB47BC, type: 1, isDefault: true),
        CategoryModel(id: 'entertainment', name: 'Entertainment', iconCode: 0xe40f, colorValue: 0xFFEC407A, type: 1, isDefault: true),
        CategoryModel(id: 'salary', name: 'Salary', iconCode: 0xf05ed, colorValue: 0xFF00E676, type: 0, isDefault: true),
        CategoryModel(id: 'other', name: 'Other', iconCode: 0xe402, colorValue: 0xFF78909C, type: 1, isDefault: true),
      ];
      for (final model in defaults) {
        await _localDatasource.add(model);
      }
    }
  }
}
