import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../../shared/models/transaction_type.dart';

/// Represents a document at users/{userId}/transactions/{transactionId}.
class TransactionModel extends Equatable {
  final String id;
  final String userId;
  final TransactionType type;
  final String categoryId;
  final double amount;
  final String description;
  final DateTime date;
  final String? recurringId;
  final String? generatedPeriod;
  final String? goalId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.date,
    this.recurringId,
    this.generatedPeriod,
    this.goalId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  factory TransactionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: TransactionTypeX.fromString(data['type'] as String? ?? 'expense'),
      categoryId: data['categoryId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recurringId: data['recurringId'] as String?,
      generatedPeriod: data['generatedPeriod'] as String?,
      goalId: data['goalId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'type': type.name,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      if (recurringId != null) 'recurringId': recurringId,
      if (generatedPeriod != null) 'generatedPeriod': generatedPeriod,
      if (goalId != null) 'goalId': goalId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'type': type.name,
      'categoryId': categoryId,
      'amount': amount,
      'description': description,
      'date': Timestamp.fromDate(date),
      if (goalId != null) 'goalId': goalId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        categoryId,
        amount,
        description,
        date,
        recurringId,
        generatedPeriod,
        goalId,
        createdAt,
        updatedAt,
      ];
}
