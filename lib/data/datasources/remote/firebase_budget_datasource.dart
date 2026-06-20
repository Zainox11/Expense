import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/data/models/budget_model.dart';

/// Remote datasource for budgets backed by Cloud Firestore.
///
/// Document path: `users/{userId}/budgets/{budgetId}`
class FirebaseBudgetDatasource {
  final FirebaseFirestore _firestore;

  FirebaseBudgetDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the budgets sub-collection for [userId].
  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets');
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Adds a budget document using the model's [id] as the document ID.
  Future<void> add(String userId, BudgetModel model) async {
    await _collection(userId).doc(model.id).set(model.toJson());
  }

  /// Updates an existing budget document.
  Future<void> update(String userId, BudgetModel model) async {
    await _collection(userId).doc(model.id).update(model.toJson());
  }

  /// Deletes the budget with the given [id].
  Future<void> delete(String userId, String id) async {
    await _collection(userId).doc(id).delete();
  }

  /// Fetches all budgets for [userId].
  Future<List<BudgetModel>> getAll(String userId) async {
    final snapshot = await _collection(userId).get();

    return snapshot.docs
        .map((doc) => BudgetModel.fromJson(doc.data()))
        .toList();
  }

  /// Fetches budgets for a specific [month] and [year].
  Future<List<BudgetModel>> getByMonth(
    String userId,
    int month,
    int year,
  ) async {
    final snapshot = await _collection(userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs
        .map((doc) => BudgetModel.fromJson(doc.data()))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Real-time stream
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of budgets for a specific month/year.
  Stream<List<BudgetModel>> watchByMonth(
    String userId,
    int month,
    int year,
  ) {
    return _collection(userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromJson(doc.data()))
            .toList());
  }

  /// Returns a real-time stream of all budgets for [userId].
  Stream<List<BudgetModel>> watchAll(String userId) {
    return _collection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromJson(doc.data()))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // Batch operations
  // ---------------------------------------------------------------------------

  /// Syncs a batch of budgets to Firestore using merge-set.
  Future<void> syncBatch(
    String userId,
    List<BudgetModel> models,
  ) async {
    final batch = _firestore.batch();
    for (final model in models) {
      final docRef = _collection(userId).doc(model.id);
      batch.set(docRef, model.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
