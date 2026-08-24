import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/goal_contribution_model.dart';
import '../models/saving_goal_model.dart';

class SavingGoalRepository {
  final FirebaseFirestore _firestore;

  SavingGoalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _goalsCollection(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.savingGoals);
  }

  CollectionReference<Map<String, dynamic>> _contributionsCollection(
      String userId, String goalId) {
    return _goalsCollection(userId).doc(goalId).collection(FirestoreCollections.contributions);
  }

  Stream<List<SavingGoalModel>> watchGoals(String userId) {
    return _goalsCollection(userId).orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map(SavingGoalModel.fromDoc).toList());
  }

  Stream<List<GoalContributionModel>> watchContributions(String userId, String goalId) {
    return _contributionsCollection(userId, goalId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(GoalContributionModel.fromDoc).toList());
  }

  Future<void> addGoal(SavingGoalModel goal) async {
    if (goal.targetAmount <= 0) {
      throw ArgumentError('Target amount must be greater than 0');
    }
    await _goalsCollection(goal.userId).add(goal.toMapForCreate());
  }

  Future<void> updateGoal(SavingGoalModel goal) async {
    if (goal.targetAmount <= 0) {
      throw ArgumentError('Target amount must be greater than 0');
    }
    await _goalsCollection(goal.userId).doc(goal.id).update(goal.toMapForUpdate());
  }

  Future<void> deleteGoal({required String userId, required String goalId}) async {
    await _goalsCollection(userId).doc(goalId).delete();
  }

  /// Records a contribution AND increments the goal's `currentAmount` in
  /// one atomic Firestore transaction, so the running total can never
  /// drift out of sync with the sum of its contribution history — even
  /// under concurrent writes.
  Future<void> addContribution({
    required String userId,
    required String goalId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Contribution amount must be greater than 0');
    }
    final goalRef = _goalsCollection(userId).doc(goalId);
    final contributionRef = _contributionsCollection(userId, goalId).doc();

    await _firestore.runTransaction((txn) async {
      final goalSnap = await txn.get(goalRef);
      final currentAmount = (goalSnap.data()?['currentAmount'] as num?)?.toDouble() ?? 0;
      txn.set(
        contributionRef,
        GoalContributionModel(id: '', amount: amount, note: note, date: date).toMapForCreate(),
      );
      txn.update(goalRef, {
        'currentAmount': currentAmount + amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
