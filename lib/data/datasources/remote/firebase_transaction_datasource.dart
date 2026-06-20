import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';

/// Remote datasource for transactions backed by Cloud Firestore.
///
/// Document path: `users/{userId}/transactions/{transactionId}`
class FirebaseTransactionDatasource {
  final FirebaseFirestore _firestore;

  FirebaseTransactionDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the transactions sub-collection for [userId].
  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Adds a transaction document. Uses the model's [id] as the document ID
  /// to allow deterministic merges.
  Future<void> add(String userId, TransactionModel model) async {
    await _collection(userId).doc(model.id).set(model.toJson());
  }

  /// Updates an existing transaction document.
  Future<void> update(String userId, TransactionModel model) async {
    await _collection(userId).doc(model.id).update(model.toJson());
  }

  /// Deletes the transaction document with the given [id].
  Future<void> delete(String userId, String id) async {
    await _collection(userId).doc(id).delete();
  }

  /// Fetches all transactions for [userId], ordered by date descending.
  Future<List<TransactionModel>> getAll(String userId) async {
    final snapshot = await _collection(userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromJson(doc.data()))
        .toList();
  }

  /// Fetches transactions within a date range (inclusive).
  /// [start] and [end] are in millisecondsSinceEpoch.
  Future<List<TransactionModel>> getByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _collection(userId)
        .where('date',
            isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: end.millisecondsSinceEpoch)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromJson(doc.data()))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Real-time stream
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of all transactions for [userId].
  /// Emits a new list every time the Firestore collection changes.
  Stream<List<TransactionModel>> watchAll(String userId) {
    return _collection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromJson(doc.data()))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // Batch operations
  // ---------------------------------------------------------------------------

  /// Syncs a batch of locally-created transactions to Firestore.
  Future<void> syncBatch(
    String userId,
    List<TransactionModel> models,
  ) async {
    final batch = _firestore.batch();
    for (final model in models) {
      final docRef = _collection(userId).doc(model.id);
      batch.set(docRef, model.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
