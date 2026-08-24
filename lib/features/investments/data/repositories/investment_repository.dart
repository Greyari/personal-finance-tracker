import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/investment_model.dart';

class InvestmentRepository {
  final FirebaseFirestore _firestore;

  InvestmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.investments);
  }

  Stream<List<InvestmentModel>> watchInvestments(String userId) {
    return _collection(userId).orderBy('date', descending: true).snapshots().map(
        (snapshot) => snapshot.docs.map(InvestmentModel.fromDoc).toList());
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    if (investment.capital <= 0) {
      throw ArgumentError('Capital must be greater than 0');
    }
    await _collection(investment.userId).add(investment.toMapForCreate());
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    if (investment.capital <= 0) {
      throw ArgumentError('Capital must be greater than 0');
    }
    await _collection(investment.userId).doc(investment.id).update(investment.toMapForUpdate());
  }

  Future<void> deleteInvestment({
    required String userId,
    required String investmentId,
  }) async {
    await _collection(userId).doc(investmentId).delete();
  }
}
