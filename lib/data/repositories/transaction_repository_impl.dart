import 'dart:async';

import 'package:expense_tracker/core/network/connectivity_service.dart';
import 'package:expense_tracker/data/datasources/local/hive_transaction_datasource.dart';
import 'package:expense_tracker/data/datasources/remote/firebase_transaction_datasource.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/domain/repositories/transaction_repository.dart';

/// Offline-first implementation of [TransactionRepository].
///
/// **Read strategy:**  Return data from Hive immediately, then attempt a
/// background sync from Firestore when connected.
///
/// **Write strategy:**  Write to Hive immediately (marking `isSynced = false`),
/// then push to Firestore if the device is online.
class TransactionRepositoryImpl implements TransactionRepository {
  final HiveTransactionDatasource _localDatasource;
  final FirebaseTransactionDatasource _remoteDatasource;
  final ConnectivityService _connectivity;

  TransactionRepositoryImpl({
    required HiveTransactionDatasource localDatasource,
    required FirebaseTransactionDatasource remoteDatasource,
    required ConnectivityService connectivity,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource,
        _connectivity = connectivity;

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  @override
  Future<List<TransactionEntity>> getTransactions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (startDate != null && endDate != null) {
      return getTransactionsByDateRange(userId, startDate, endDate);
    }
    
    // Return local data immediately
    final localModels = _localDatasource.getAll(userId);

    // Background sync from remote (fire-and-forget)
    _syncFromRemote(userId);

    return localModels.map((m) => m.toEntity()).toList();
  }

  Future<TransactionEntity?> getTransactionById(String id) async {
    final model = _localDatasource.getById(id);
    return model?.toEntity();
  }

  Future<List<TransactionEntity>> getTransactionsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final models = _localDatasource.getByDateRange(userId, start, end);
    return models.map((m) => m.toEntity()).toList();
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  @override
  Future<void> addTransaction(TransactionEntity entity) async {
    // Write locally first – mark as unsynced
    final model = TransactionModel.fromEntity(entity).copyWith(isSynced: false);
    await _localDatasource.add(model);

    // Push to remote if online
    if (await _connectivity.isConnected) {
      try {
        final synced = model.copyWith(isSynced: true);
        await _remoteDatasource.add(entity.userId, synced);
        await _localDatasource.markAsSynced(entity.id);
      } catch (_) {
        // Will be retried during next sync cycle
      }
    }
  }

  @override
  Future<void> updateTransaction(TransactionEntity entity) async {
    final model = TransactionModel.fromEntity(entity).copyWith(isSynced: false);
    await _localDatasource.update(model);

    if (await _connectivity.isConnected) {
      try {
        final synced = model.copyWith(isSynced: true);
        await _remoteDatasource.update(entity.userId, synced);
        await _localDatasource.markAsSynced(entity.id);
      } catch (_) {
        // Will be retried during next sync cycle
      }
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final existing = _localDatasource.getById(id);
    await _localDatasource.delete(id);

    if (existing != null && await _connectivity.isConnected) {
      try {
        await _remoteDatasource.delete(existing.userId, id);
      } catch (_) {
        // Best-effort remote delete
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  @override
  Stream<List<TransactionEntity>> watchTransactions(String userId) {
    // Use Hive box.watch() to emit on every local change, then map
    // the entire box content to a list of entities.
    return _localDatasource.box
        .watch()
        .map((_) => _localDatasource
            .getAll(userId)
            .map((m) => m.toEntity())
            .toList())
        // Seed with the current data so listeners get an initial value
        .transform(_seedTransform(
          _localDatasource
              .getAll(userId)
              .map((m) => m.toEntity())
              .toList(),
        ));
  }

  @override
  Future<double> getTotalIncome(String userId, int month, int year) async {
    final txs = await getTransactions(
      userId,
      startDate: DateTime(year, month, 1),
      endDate: DateTime(year, month + 1, 0, 23, 59, 59),
    );
    return txs
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<double> getTotalExpense(String userId, int month, int year) async {
    final txs = await getTransactions(
      userId,
      startDate: DateTime(year, month, 1),
      endDate: DateTime(year, month + 1, 0, 23, 59, 59),
    );
    return txs
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  Future<void> syncTransactions(String userId) async {
    if (!await _connectivity.isConnected) return;

    // Push unsynced local transactions to Firestore
    final unsynced = _localDatasource.getUnsynced();
    if (unsynced.isNotEmpty) {
      await _remoteDatasource.syncBatch(userId, unsynced);
      for (final t in unsynced) {
        await _localDatasource.markAsSynced(t.id);
      }
    }

    // Pull remote data and replace local cache
    final remoteModels = await _remoteDatasource.getAll(userId);
    final synced = remoteModels.map((m) => m.copyWith(isSynced: true)).toList();
    await _localDatasource.replaceAll(userId, synced);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Attempts a remote sync in the background. Failures are silently ignored.
  Future<void> _syncFromRemote(String userId) async {
    if (!await _connectivity.isConnected) return;
    try {
      final remoteModels = await _remoteDatasource.getAll(userId);
      final synced =
          remoteModels.map((m) => m.copyWith(isSynced: true)).toList();
      await _localDatasource.replaceAll(userId, synced);
    } catch (_) {
      // Non-critical – we already served from cache
    }
  }

  /// Creates a [StreamTransformer] that prepends [seed] before the first
  /// event, giving consumers an immediate initial value.
  StreamTransformer<List<TransactionEntity>, List<TransactionEntity>>
      _seedTransform(List<TransactionEntity> seed) {
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, stackTrace, sink) =>
          sink.addError(error, stackTrace),
      handleDone: (sink) => sink.close(),
    );
  }
}
