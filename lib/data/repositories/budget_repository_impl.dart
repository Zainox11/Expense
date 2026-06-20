import 'dart:async';

import 'package:expense_tracker/core/network/connectivity_service.dart';
import 'package:expense_tracker/data/datasources/local/hive_budget_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_budget_datasource.dart';
import 'package:expense_tracker/data/models/budget_model.dart';
import 'package:expense_tracker/domain/entities/budget_entity.dart';
import 'package:expense_tracker/domain/repositories/budget_repository.dart';

/// Offline-first implementation of [BudgetRepository].
///
/// Follows the same read-local / write-local-first pattern as the other
/// repository implementations.
class BudgetRepositoryImpl implements BudgetRepository {
  final HiveBudgetDatasource _localDatasource;
  final FirebaseBudgetDatasource _remoteDatasource;
  final ConnectivityService _connectivity;

  BudgetRepositoryImpl({
    required HiveBudgetDatasource localDatasource,
    required FirebaseBudgetDatasource remoteDatasource,
    required ConnectivityService connectivity,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource,
        _connectivity = connectivity;

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  Future<List<BudgetEntity>> getBudgets(String userId) async {
    final models = _localDatasource.getAll(userId);

    // Background sync
    _syncFromRemote(userId);

    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BudgetEntity?> getBudgetById(String id) async {
    final model = _localDatasource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<List<BudgetEntity>> getBudgetsByMonth(
    String userId,
    int month,
    int year,
  ) async {
    final models = _localDatasource.getByMonth(userId, month, year);
    return models.map((m) => m.toEntity()).toList();
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  @override
  Future<void> setBudget(BudgetEntity entity) async {
    final model = BudgetModel.fromEntity(entity);
    await _localDatasource.add(model);

    if (await _connectivity.isConnected) {
      try {
        await _remoteDatasource.add(entity.userId, model);
      } catch (_) {
        // Will be synced later
      }
    }
  }

  @override
  Future<void> updateBudget(BudgetEntity entity) async {
    final model = BudgetModel.fromEntity(entity);
    await _localDatasource.update(model);

    if (await _connectivity.isConnected) {
      try {
        await _remoteDatasource.update(entity.userId, model);
      } catch (_) {
        // Will be synced later
      }
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    final existing = _localDatasource.getById(id);
    await _localDatasource.delete(id);

    if (existing != null && await _connectivity.isConnected) {
      try {
        await _remoteDatasource.delete(existing.userId, id);
      } catch (_) {
        // Best-effort
      }
    }
  }

  @override
  Future<void> updateSpentAmount(
    String userId,
    String categoryId,
    int month,
    int year,
    double spentAmount,
  ) async {
    final models = _localDatasource.getByMonth(userId, month, year);
    final match = models.cast<BudgetModel?>().firstWhere(
      (m) => m?.categoryId == categoryId,
      orElse: () => null,
    );
    if (match == null) return;

    final updated = match.copyWith(spent: spentAmount);
    await _localDatasource.update(updated);

    if (await _connectivity.isConnected) {
      try {
        await _remoteDatasource.update(userId, updated);
      } catch (_) {
        // Will be synced later
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  Stream<List<BudgetEntity>> watchBudgets(String userId) {
    return _localDatasource.box
        .watch()
        .map((_) => _localDatasource
            .getAll(userId)
            .map((m) => m.toEntity())
            .toList());
  }

  Stream<List<BudgetEntity>> watchBudgetsByMonth(
    String userId,
    int month,
    int year,
  ) {
    return _localDatasource.box
        .watch()
        .map((_) => _localDatasource
            .getByMonth(userId, month, year)
            .map((m) => m.toEntity())
            .toList());
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  Future<void> syncBudgets(String userId) async {
    if (!await _connectivity.isConnected) return;

    try {
      // Push local budgets to remote
      final localModels = _localDatasource.getAll(userId);
      if (localModels.isNotEmpty) {
        await _remoteDatasource.syncBatch(userId, localModels);
      }

      // Pull remote budgets into local cache
      final remoteModels = await _remoteDatasource.getAll(userId);
      await _localDatasource.replaceAll(userId, remoteModels);
    } catch (_) {
      // Non-critical
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _syncFromRemote(String userId) async {
    if (!await _connectivity.isConnected) return;
    try {
      final remoteModels = await _remoteDatasource.getAll(userId);
      await _localDatasource.replaceAll(userId, remoteModels);
    } catch (_) {
      // Non-critical
    }
  }
}
