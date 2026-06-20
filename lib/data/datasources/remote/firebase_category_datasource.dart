import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/data/models/category_model.dart';

/// Remote datasource for categories backed by Cloud Firestore.
///
/// Document path: `users/{userId}/categories/{categoryId}`
class FirebaseCategoryDatasource {
  final FirebaseFirestore _firestore;

  FirebaseCategoryDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the categories sub-collection for [userId].
  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories');
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Adds a category document using the model's [id] as the document ID.
  Future<void> add(String userId, CategoryModel model) async {
    await _collection(userId).doc(model.id).set(model.toJson());
  }

  /// Updates an existing category document.
  Future<void> update(String userId, CategoryModel model) async {
    await _collection(userId).doc(model.id).update(model.toJson());
  }

  /// Deletes the category with the given [id].
  Future<void> delete(String userId, String id) async {
    await _collection(userId).doc(id).delete();
  }

  /// Fetches all categories for [userId], ordered by name.
  Future<List<CategoryModel>> getAll(String userId) async {
    final snapshot = await _collection(userId)
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => CategoryModel.fromJson(doc.data()))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Real-time stream
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of all categories for [userId].
  Stream<List<CategoryModel>> watchAll(String userId) {
    return _collection(userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromJson(doc.data()))
            .toList());
  }

  // ---------------------------------------------------------------------------
  // Batch operations
  // ---------------------------------------------------------------------------

  /// Syncs a batch of categories to Firestore using merge-set.
  Future<void> syncBatch(
    String userId,
    List<CategoryModel> models,
  ) async {
    final batch = _firestore.batch();
    for (final model in models) {
      final docRef = _collection(userId).doc(model.id);
      batch.set(docRef, model.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
