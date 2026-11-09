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

  /// Adds a contribution tied directly to a transaction, using the transactionId as
  /// the contribution doc ID so it can be updated or deleted in perfect sync.
  Future<void> addContributionFromTransaction({
    required String userId,
    required String goalId,
    required String transactionId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    if (amount <= 0) return;
    final goalRef = _goalsCollection(userId).doc(goalId);
    final contribRef = _contributionsCollection(userId, goalId).doc(transactionId);

    await _firestore.runTransaction((txn) async {
      final goalSnap = await txn.get(goalRef);
      if (!goalSnap.exists) return;
      final currentAmount = (goalSnap.data()?['currentAmount'] as num?)?.toDouble() ?? 0;
      txn.set(
        contribRef,
        GoalContributionModel(id: transactionId, amount: amount, note: note, date: date).toMapForCreate(),
      );
      txn.update(goalRef, {
        'currentAmount': currentAmount + amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Updates a contribution when a transaction is edited (amount changed, goal changed, etc.).
  Future<void> updateContributionFromTransaction({
    required String userId,
    required String transactionId,
    required String newGoalId,
    required double newAmount,
    required String newNote,
    required DateTime newDate,
    required String? oldGoalId,
    required double oldAmount,
  }) async {
    if (oldGoalId != null && oldGoalId != newGoalId) {
      // Goal changed from Goal A to Goal B
      final oldGoalRef = _goalsCollection(userId).doc(oldGoalId);
      final oldContribRef = _contributionsCollection(userId, oldGoalId).doc(transactionId);
      final newGoalRef = _goalsCollection(userId).doc(newGoalId);
      final newContribRef = _contributionsCollection(userId, newGoalId).doc(transactionId);

      await _firestore.runTransaction((txn) async {
        final oldSnap = await txn.get(oldGoalRef);
        if (oldSnap.exists) {
          final oldCur = (oldSnap.data()?['currentAmount'] as num?)?.toDouble() ?? 0;
          txn.update(oldGoalRef, {
            'currentAmount': (oldCur - oldAmount).clamp(0.0, double.infinity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          txn.delete(oldContribRef);
        }

        final newSnap = await txn.get(newGoalRef);
        if (newSnap.exists) {
          final newCur = (newSnap.data()?['currentAmount'] as num?)?.toDouble() ?? 0;
          txn.update(newGoalRef, {
            'currentAmount': newCur + newAmount,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          txn.set(
            newContribRef,
            GoalContributionModel(id: transactionId, amount: newAmount, note: newNote, date: newDate).toMapForCreate(),
          );
        }
      });
    } else {
      // Same goal, update amount, note, and date
      final goalRef = _goalsCollection(userId).doc(newGoalId);
      final contribRef = _contributionsCollection(userId, newGoalId).doc(transactionId);

      await _firestore.runTransaction((txn) async {
        final goalSnap = await txn.get(goalRef);
        if (!goalSnap.exists) return;
        final currentAmount = (goalSnap.data()?['currentAmount'] as num?)?.toDouble() ?? 0;
        final diff = newAmount - oldAmount;
        final updatedAmount = (currentAmount + diff).clamp(0.0, double.infinity);

        txn.set(
          contribRef,
          GoalContributionModel(id: transactionId, amount: newAmount, note: newNote, date: newDate).toMapForCreate(),
        );
        txn.update(goalRef, {
          'currentAmount': updatedAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    }
  }

  /// Deletes a contribution when a transaction is deleted or recategorized away from saving.
  Future<void> deleteContributionFromTransaction({
    required String userId,
    required String goalId,
    required String transactionId,
    required double amount,
  }) async {
    final goalRef = _goalsCollection(userId).doc(goalId);
    final contribRef = _contributionsCollection(userId, goalId).doc(transactionId);

    await _firestore.runTransaction((txn) async {
      final goalSnap = await txn.get(goalRef);
      if (goalSnap.exists) {
        final currentAmount = (goalSnap.data()?['currentAmount'] as num?)?.toDouble() ?? 0;
        final newAmount = (currentAmount - amount).clamp(0.0, double.infinity);
        txn.update(goalRef, {
          'currentAmount': newAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      txn.delete(contribRef);
    });
  }

  /// Legacy manual add contribution (if called from tests or scripts)
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
