import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/default_categories.dart';
import '../../../../shared/models/transaction_type.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.categories);
  }

  /// Called once, right after a new user registers (see
  /// AuthController.register). Writes all default categories in a
  /// single batch. Guarded by an existence check so it's safe to call
  /// more than once — e.g. if registration is retried — without ever
  /// creating duplicates.
  Future<void> seedDefaultCategoriesIfNeeded(String userId) async {
    final existing = await _collection(userId).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final def in defaultCategories) {
      final docRef = _collection(userId).doc();
      batch.set(docRef, {
        'name': def.name,
        'type': def.type.name,
        'icon': def.icon,
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Streams categories for one user, optionally filtered by type.
  /// Pass null to get every category regardless of type (used by the
  /// transaction list to resolve category names/icons for display).
  Stream<List<CategoryModel>> watchCategories(String userId, {TransactionType? type}) {
    Query<Map<String, dynamic>> query = _collection(userId).orderBy('name');
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    return query.snapshots().map(
        (snapshot) => snapshot.docs.map(CategoryModel.fromDoc).toList());
  }

  Future<void> addCategory({
    required String userId,
    required String name,
    required TransactionType type,
    required String icon,
  }) async {
    final category = CategoryModel(id: '', name: name, type: type, icon: icon);
    await _collection(userId).add(category.toMapForCreate());
  }

  Future<void> updateCategory({
    required String userId,
    required CategoryModel category,
  }) async {
    await _collection(userId).doc(category.id).update(category.toMapForUpdate());
  }

  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) async {
    await _collection(userId).doc(categoryId).delete();
  }

  /// Looks up a category's ID by exact name. Used once, right after
  /// seeding, so AuthController can link the default "Gereja" recurring
  /// transaction (Section 13) to the "Gereja" category that was just
  /// created — without hardcoding a category ID anywhere.
  Future<String?> getCategoryIdByName(String userId, String name) async {
    final snapshot = await _collection(userId).where('name', isEqualTo: name).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }
}
