import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../models/recurring_transaction_model.dart';

class RecurringTransactionRepository {
  final FirebaseFirestore _firestore;

  RecurringTransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.recurringTransactions);
  }

  CollectionReference<Map<String, dynamic>> _transactionsCollection(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.transactions);
  }

  Stream<List<RecurringTransactionModel>> watchRecurring(String userId) {
    return _collection(userId).orderBy('createdAt').snapshots().map(
        (snapshot) => snapshot.docs.map(RecurringTransactionModel.fromDoc).toList());
  }

  void _assertValid(bool isPercentage, double value) {
    if (value <= 0) throw ArgumentError('Value must be greater than 0');
    if (isPercentage && value > 100) throw ArgumentError('Percentage cannot exceed 100');
  }

  Future<void> addRecurring(RecurringTransactionModel recurring) async {
    _assertValid(recurring.isPercentage, recurring.value);
    await _collection(recurring.userId).add(recurring.toMapForCreate());
  }

  Future<void> updateRecurring(RecurringTransactionModel recurring) async {
    _assertValid(recurring.isPercentage, recurring.value);
    await _collection(recurring.userId).doc(recurring.id).update(recurring.toMapForUpdate());
  }

  Future<void> deleteRecurring({
    required String userId,
    required String recurringId,
  }) async {
    await _collection(userId).doc(recurringId).delete();
  }

  Future<void> setActive({
    required String userId,
    required String recurringId,
    required bool isActive,
  }) async {
    await _collection(userId).doc(recurringId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Section 13's "Gereja 10%" gets seeded once for every new user,
  /// linked to their default "Gereja" category, fully editable afterward.
  /// Guarded the same way category seeding is, so it's safe even if
  /// registration were somehow retried.
  Future<void> seedDefaultChurchRecurringIfNeeded({
    required String userId,
    required String categoryId,
  }) async {
    final existing =
        await _collection(userId).where('name', isEqualTo: 'Gereja').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    await _collection(userId).add({
      'userId': userId,
      'name': 'Gereja',
      'type': TransactionType.expense.name,
      'categoryId': categoryId,
      'isPercentage': true,
      'value': 10,
      'isActive': true,
      'frequency': 'monthly',
      'lastGeneratedPeriod': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// The core of Section 14: for every active recurring config that
  /// hasn't generated a transaction for [period] yet, creates one and
  /// stamps `lastGeneratedPeriod`. [monthlyIncome] resolves any
  /// percentage-based configs (e.g. Gereja 10%).
  ///
  /// Guarded twice against duplicates (business rule 8): the
  /// `lastGeneratedPeriod` field check, AND a query for an existing
  /// generated transaction for this exact recurringId + period — so a
  /// partially-failed previous run can't create a second transaction.
  ///
  /// This runs client-side (triggered from MainShell on app open) rather
  /// than via a scheduled Cloud Function, since the spec only calls for
  /// Cloud Functions "if truly needed" and a personal app opened at
  /// least once a month satisfies Section 14 without one.
  Future<int> generateForPeriodIfNeeded({
    required String userId,
    required String period, // 'YYYY-MM'
    required double monthlyIncome,
  }) async {
    final snapshot = await _collection(userId).where('isActive', isEqualTo: true).get();
    var generatedCount = 0;

    for (final doc in snapshot.docs) {
      final recurring = RecurringTransactionModel.fromDoc(doc);
      if (recurring.lastGeneratedPeriod == period) continue;

      final alreadyExists = await _transactionsCollection(userId)
          .where('recurringId', isEqualTo: recurring.id)
          .where('generatedPeriod', isEqualTo: period)
          .limit(1)
          .get();
      if (alreadyExists.docs.isNotEmpty) {
        await doc.reference.update({'lastGeneratedPeriod': period});
        continue;
      }

      final amount = recurring.resolvedAmount(monthlyIncome);
      if (amount <= 0) continue; // e.g. a percentage of Rp0 income so far

      final periodParts = period.split('-');
      final year = int.parse(periodParts[0]);
      final month = int.parse(periodParts[1]);

      final transaction = TransactionModel(
        id: '',
        userId: userId,
        type: recurring.type,
        categoryId: recurring.categoryId,
        amount: amount,
        description: recurring.name,
        date: DateTime(year, month, 1),
      );

      final batch = _firestore.batch();
      final txRef = _transactionsCollection(userId).doc();
      batch.set(txRef, {
        ...transaction.toMapForCreate(),
        'recurringId': recurring.id,
        'generatedPeriod': period,
      });
      batch.update(doc.reference, {
        'lastGeneratedPeriod': period,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      generatedCount++;
    }

    return generatedCount;
  }
}
