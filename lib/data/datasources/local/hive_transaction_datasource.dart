import 'package:hive/hive.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';

/// Local datasource for transactions backed by a Hive box.
///
/// All operations are synchronous from the caller's perspective because
/// Hive keeps the box data in memory after opening.
class HiveTransactionDatasource {
  static const String boxName = 'transactions';

  final Box<TransactionModel> _box;

  HiveTransactionDatasource(this._box);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Returns all transactions belonging to [userId], newest first.
  List<TransactionModel> getAll(String userId) {
    return _box.values
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Returns a single transaction by [id], or `null` if not found.
  TransactionModel? getById(String id) {
    try {
      return _box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new transaction to the box, keyed by its [model.id].
  Future<void> add(TransactionModel model) async {
    await _box.put(model.id, model);
  }

  /// Updates an existing transaction (same key strategy).
  Future<void> update(TransactionModel model) async {
    await _box.put(model.id, model);
  }

  /// Deletes the transaction with the given [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns transactions for [userId] whose date falls within [start]–[end]
  /// (inclusive), sorted newest first.
  List<TransactionModel> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    return _box.values
        .where((t) =>
            t.userId == userId && t.date >= startMs && t.date <= endMs)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Returns all transactions that have not yet been synced to the server.
  List<TransactionModel> getUnsynced() {
    return _box.values.where((t) => !t.isSynced).toList();
  }

  /// Marks the transaction with [id] as synced by writing a copy with
  /// `isSynced = true`.
  Future<void> markAsSynced(String id) async {
    final existing = getById(id);
    if (existing != null) {
      await _box.put(id, existing.copyWith(isSynced: true));
    }
  }

  // ---------------------------------------------------------------------------
  // Bulk operations
  // ---------------------------------------------------------------------------

  /// Replaces all local transactions for [userId] with [models].
  /// Useful after a full sync from the server.
  Future<void> replaceAll(String userId, List<TransactionModel> models) async {
    // Remove old entries for this user
    final keysToRemove = _box.keys
        .where((key) {
          final item = _box.get(key);
          return item != null && item.userId == userId;
        })
        .toList();
    await _box.deleteAll(keysToRemove);

    // Add new entries
    final entries = {for (final m in models) m.id: m};
    await _box.putAll(entries);
  }

  /// Exposes the underlying box for watching changes via
  /// `box.watch()` in repository implementations.
  Box<TransactionModel> get box => _box;
}
