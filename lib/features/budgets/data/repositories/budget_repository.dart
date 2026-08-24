import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore _firestore;

  BudgetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.budgets);
  }

  /// Business rules: "Budget tidak boleh negatif" and a percentage can't
  /// exceed 100. Enforced here in addition to the form validator and
  /// firestore.rules.
  void _assertValid(bool isPercentage, double value) {
    if (value <= 0) {
      throw ArgumentError('Budget value must be greater than 0');
    }
    if (isPercentage && value > 100) {
      throw ArgumentError('Percentage cannot exceed 100');
    }
  }

  Stream<List<BudgetModel>> watchBudgets(String userId) {
    return _collection(userId).orderBy('createdAt').snapshots().map(
        (snapshot) => snapshot.docs.map(BudgetModel.fromDoc).toList());
  }

  Future<void> addBudget(BudgetModel budget) async {
    _assertValid(budget.isPercentage, budget.value);
    await _collection(budget.userId).add(budget.toMapForCreate());
  }

  Future<void> updateBudget(BudgetModel budget) async {
    _assertValid(budget.isPercentage, budget.value);
    await _collection(budget.userId).doc(budget.id).update(budget.toMapForUpdate());
  }

  Future<void> deleteBudget({
    required String userId,
    required String budgetId,
  }) async {
    await _collection(userId).doc(budgetId).delete();
  }

  /// Quick toggle for the active/inactive switch in the Budget list —
  /// doesn't go through the full update map since only one field changes.
  Future<void> setActive({
    required String userId,
    required String budgetId,
    required bool isActive,
  }) async {
    await _collection(userId).doc(budgetId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
