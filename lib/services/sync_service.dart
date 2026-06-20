import 'package:flutter/foundation.dart';

import 'package:expense_tracker/core/network/connectivity_service.dart';
import 'package:expense_tracker/data/datasources/local/hive_transaction_datasource.dart';
import 'package:expense_tracker/data/datasources/local/hive_category_datasource.dart';
import 'package:expense_tracker/data/datasources/local/hive_budget_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_transaction_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_category_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_budget_datasource.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/models/category_model.dart';
import 'package:expense_tracker/data/models/budget_model.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/entities/category_entity.dart';
import 'package:expense_tracker/domain/entities/budget_entity.dart';

/// Result of a sync operation with statistics about what changed.
class SyncResult {
  final int pushed;
  final int pulled;
  final int conflicts;
  final List<String> errors;

  const SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.errors = const [],
  });

  int get pushedCount => pushed;
  int get pulledCount => pulled;
  int get conflictCount => conflicts;

  SyncResult merge(SyncResult other) {
    return SyncResult(
      pushed: pushed + other.pushed,
      pulled: pulled + other.pulled,
      conflicts: conflicts + other.conflicts,
      errors: [...errors, ...other.errors],
    );
  }

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() =>
      'SyncResult(pushed=$pushed, pulled=$pulled, '
      'conflicts=$conflicts, errors=${errors.length})';
}

/// Service that handles bidirectional synchronization between local Hive storage
/// and remote Firestore.
class SyncService {
  SyncService({
    required ConnectivityService connectivityService,
    required HiveTransactionDatasource localTransactionDatasource,
    required FirebaseTransactionDatasource remoteTransactionDatasource,
    required HiveCategoryDatasource localCategoryDatasource,
    required FirebaseCategoryDatasource remoteCategoryDatasource,
    required HiveBudgetDatasource localBudgetDatasource,
    required FirebaseBudgetDatasource remoteBudgetDatasource,
  })  : _connectivity = connectivityService,
        _txLocal = localTransactionDatasource,
        _txRemote = remoteTransactionDatasource,
        _catLocal = localCategoryDatasource,
        _catRemote = remoteCategoryDatasource,
        _budgetLocal = localBudgetDatasource,
        _budgetRemote = remoteBudgetDatasource;

  final ConnectivityService _connectivity;

  // Transaction datasources
  final HiveTransactionDatasource _txLocal;
  final FirebaseTransactionDatasource _txRemote;

  // Category datasources
  final HiveCategoryDatasource _catLocal;
  final FirebaseCategoryDatasource _catRemote;

  // Budget datasources
  final HiveBudgetDatasource _budgetLocal;
  final FirebaseBudgetDatasource _budgetRemote;

  /// Whether a sync is currently in progress (prevents overlapping syncs).
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // ---------------------------------------------------------------------------
  // Full Sync
  // ---------------------------------------------------------------------------

  /// Synchronize all data (transactions, categories, budgets) for [userId].
  Future<SyncResult> syncAll(String userId) async {
    if (_isSyncing) {
      debugPrint('SyncService: Sync already in progress — skipping');
      return const SyncResult();
    }

    final isConnected = await _connectivity.isConnected;
    if (!isConnected) {
      debugPrint('SyncService: No network connection — skipping sync');
      return const SyncResult(
        errors: ['No network connection available'],
      );
    }

    _isSyncing = true;
    debugPrint('SyncService: Starting full sync for user=$userId');

    try {
      final txResult = await syncTransactions(userId);
      final catResult = await syncCategories(userId);
      final budgetResult = await syncBudgets(userId);

      final combined = txResult.merge(catResult).merge(budgetResult);
      debugPrint('SyncService: Full sync complete — $combined');
      return combined;
    } catch (e) {
      debugPrint('SyncService: Full sync failed — $e');
      return SyncResult(errors: ['Full sync failed: $e']);
    } finally {
      _isSyncing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Transaction Sync
  // ---------------------------------------------------------------------------

  /// Bidirectional sync of transactions for [userId].
  Future<SyncResult> syncTransactions(String userId) async {
    int pushed = 0;
    int pulled = 0;
    int conflicts = 0;
    final errors = <String>[];

    try {
      // ── Step 1: Push unsynced local transactions to remote ──
      final localTransactions = _txLocal.getAll(userId).map((m) => m.toEntity()).toList();
      final unsynced = localTransactions.where((t) => !t.isSynced).toList();

      for (final localTx in unsynced) {
        try {
          final model = TransactionModel.fromEntity(localTx);
          await _txRemote.add(userId, model);

          // Mark as synced locally
          final syncedEntity = TransactionEntity(
            id: localTx.id,
            userId: localTx.userId,
            amount: localTx.amount,
            type: localTx.type,
            categoryId: localTx.categoryId,
            note: localTx.note,
            date: localTx.date,
            createdAt: localTx.createdAt,
            recurrence: localTx.recurrence,
            isSynced: true,
          );
          await _txLocal.update(
            TransactionModel.fromEntity(syncedEntity),
          );
          pushed++;
        } catch (e) {
          errors.add('Failed to push transaction ${localTx.id}: $e');
        }
      }

      // ── Step 2: Pull remote transactions and merge locally ──
      final remoteTransactions = await _txRemote.getAll(userId);
      final localMap = <String, TransactionEntity>{};
      for (final tx in localTransactions) {
        localMap[tx.id] = tx;
      }

      for (final remoteModel in remoteTransactions) {
        try {
          final remoteEntity = remoteModel.toEntity();
          final localEntity = localMap[remoteEntity.id];

          if (localEntity == null) {
            // New from remote — insert locally
            final syncedModel = TransactionModel.fromEntity(
              TransactionEntity(
                id: remoteEntity.id,
                userId: remoteEntity.userId,
                amount: remoteEntity.amount,
                type: remoteEntity.type,
                categoryId: remoteEntity.categoryId,
                note: remoteEntity.note,
                date: remoteEntity.date,
                createdAt: remoteEntity.createdAt,
                recurrence: remoteEntity.recurrence,
                isSynced: true,
              ),
            );
            await _txLocal.add(syncedModel);
            pulled++;
          } else {
            // Conflict resolution: last-write-wins based on createdAt
            if (remoteEntity.createdAt.isAfter(localEntity.createdAt)) {
              final syncedModel = TransactionModel.fromEntity(
                TransactionEntity(
                  id: remoteEntity.id,
                  userId: remoteEntity.userId,
                  amount: remoteEntity.amount,
                  type: remoteEntity.type,
                  categoryId: remoteEntity.categoryId,
                  note: remoteEntity.note,
                  date: remoteEntity.date,
                  createdAt: remoteEntity.createdAt,
                  recurrence: remoteEntity.recurrence,
                  isSynced: true,
                ),
              );
              await _txLocal.update(syncedModel);
              conflicts++;
              pulled++;
            }
          }
        } catch (e) {
          errors.add('Failed to pull transaction: $e');
        }
      }
    } catch (e) {
      errors.add('Transaction sync failed: $e');
    }

    final result = SyncResult(
      pushed: pushed,
      pulled: pulled,
      conflicts: conflicts,
      errors: errors,
    );
    debugPrint('SyncService: Transactions — $result');
    return result;
  }

  // ---------------------------------------------------------------------------
  // Category Sync
  // ---------------------------------------------------------------------------

  /// Bidirectional sync of categories for [userId].
  Future<SyncResult> syncCategories(String userId) async {
    int pushed = 0;
    int pulled = 0;
    int conflicts = 0;
    final errors = <String>[];

    try {
      // ── Push local categories to remote ──
      final localCategories = _catLocal.getAll().map((m) => m.toEntity()).toList();

      for (final localCat in localCategories) {
        try {
          final model = CategoryModel.fromEntity(localCat);
          // Upsert on remote using set doc
          await _catRemote.add(userId, model);
          pushed++;
        } catch (e) {
          errors.add('Failed to push category ${localCat.id}: $e');
        }
      }

      // ── Pull remote categories and merge locally ──
      final remoteCategories = await _catRemote.getAll(userId);
      final localMap = <String, CategoryEntity>{};
      for (final cat in localCategories) {
        localMap[cat.id] = cat;
      }

      for (final remoteModel in remoteCategories) {
        try {
          final remoteEntity = remoteModel.toEntity();
          final localEntity = localMap[remoteEntity.id];

          if (localEntity == null) {
            // New from remote — insert locally
            await _catLocal.add(
              CategoryModel.fromEntity(remoteEntity),
            );
            pulled++;
          } else {
            // For categories, remote wins if names differ (simple merge)
            if (remoteEntity.name != localEntity.name ||
                remoteEntity.iconCode != localEntity.iconCode ||
                remoteEntity.colorValue != localEntity.colorValue) {
              await _catLocal.update(
                CategoryModel.fromEntity(remoteEntity),
              );
              conflicts++;
              pulled++;
            }
          }
        } catch (e) {
          errors.add('Failed to pull category: $e');
        }
      }
    } catch (e) {
      errors.add('Category sync failed: $e');
    }

    final result = SyncResult(
      pushed: pushed,
      pulled: pulled,
      conflicts: conflicts,
      errors: errors,
    );
    debugPrint('SyncService: Categories — $result');
    return result;
  }

  // ---------------------------------------------------------------------------
  // Budget Sync
  // ---------------------------------------------------------------------------

  /// Bidirectional sync of budgets for [userId].
  Future<SyncResult> syncBudgets(String userId) async {
    int pushed = 0;
    int pulled = 0;
    int conflicts = 0;
    final errors = <String>[];

    try {
      // ── Push local budgets to remote ──
      final localBudgets = _budgetLocal.getAll(userId).map((m) => m.toEntity()).toList();

      for (final localBudget in localBudgets) {
        try {
          final model = BudgetModel.fromEntity(localBudget);
          await _budgetRemote.add(userId, model);
          pushed++;
        } catch (e) {
          errors.add('Failed to push budget ${localBudget.id}: $e');
        }
      }

      // ── Pull remote budgets and merge locally ──
      final remoteBudgets = await _budgetRemote.getAll(userId);
      final localMap = <String, BudgetEntity>{};
      for (final budget in localBudgets) {
        localMap[budget.id] = budget;
      }

      for (final remoteModel in remoteBudgets) {
        try {
          final remoteEntity = remoteModel.toEntity();
          final localEntity = localMap[remoteEntity.id];

          if (localEntity == null) {
            // New from remote — insert locally
            await _budgetLocal.add(
              BudgetModel.fromEntity(remoteEntity),
            );
            pulled++;
          } else {
            // Last-write-wins: compare spent amounts — higher spent = more recent
            // Also update if budget amount changed on remote
            if (remoteEntity.spent > localEntity.spent ||
                remoteEntity.amount != localEntity.amount) {
              await _budgetLocal.update(
                BudgetModel.fromEntity(remoteEntity),
              );
              conflicts++;
              pulled++;
            }
          }
        } catch (e) {
          errors.add('Failed to pull budget: $e');
        }
      }
    } catch (e) {
      errors.add('Budget sync failed: $e');
    }

    final result = SyncResult(
      pushed: pushed,
      pulled: pulled,
      conflicts: conflicts,
      errors: errors,
    );
    debugPrint('SyncService: Budgets — $result');
    return result;
  }
}
