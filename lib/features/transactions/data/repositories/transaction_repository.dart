import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;

  TransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.transactions);
  }

  /// Business rule: "amount transaksi harus lebih besar dari 0". Enforced
  /// here as a second line of defense behind the form's validator, and
  /// mirrored server-side in firestore.rules so it holds even if a
  /// client is compromised or bypassed.
  void _assertValidAmount(double amount) {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
  }

  Future<String> addTransaction(TransactionModel transaction) async {
    _assertValidAmount(transaction.amount);
    final docRef = transaction.id.isNotEmpty
        ? _collection(transaction.userId).doc(transaction.id)
        : _collection(transaction.userId).doc();
    await docRef.set(transaction.toMapForCreate());
    return docRef.id;
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    _assertValidAmount(transaction.amount);
    await _collection(transaction.userId)
        .doc(transaction.id)
        .update(transaction.toMapForUpdate());
  }

  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    await _collection(userId).doc(transactionId).delete();
  }

  /// Streams every transaction whose `date` falls within the given
  /// calendar month, newest first. This is the query the transaction
  /// list uses today, and the same query the dashboard, budget progress,
  /// and monthly report features will reuse.
  Stream<List<TransactionModel>> watchTransactionsForMonth(
    String userId, {
    required int year,
    required int month,
  }) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    return _collection(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TransactionModel.fromDoc).toList());
  }
}
