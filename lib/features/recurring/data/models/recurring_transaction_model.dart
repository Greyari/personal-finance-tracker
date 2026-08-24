import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../../shared/models/transaction_type.dart';

/// Represents a document at
/// users/{userId}/recurring_transactions/{recurringId}.
///
/// Shares the same nominal/percentage shape as BudgetModel by design —
/// "Gereja 10%" is naturally expressed as isPercentage: true, value: 10 —
/// but a RecurringTransaction actually spawns real Transaction documents
/// each month (see RecurringTransactionRepository.generateForPeriodIfNeeded),
/// whereas a Budget never does.
class RecurringTransactionModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final TransactionType type;
  final String categoryId;
  final bool isPercentage;
  final double value;
  final bool isActive;

  /// 'YYYY-MM' of the last month a transaction was generated for this
  /// config, or null if never generated. Prevents duplicate generation
  /// for the same period (business rule 8).
  final String? lastGeneratedPeriod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.categoryId,
    required this.isPercentage,
    required this.value,
    this.isActive = true,
    this.lastGeneratedPeriod,
    this.createdAt,
    this.updatedAt,
  });

  double resolvedAmount(double monthlyIncome) {
    if (isPercentage) return monthlyIncome * value / 100;
    return value;
  }

  factory RecurringTransactionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RecurringTransactionModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: TransactionTypeX.fromString(data['type'] as String? ?? 'expense'),
      categoryId: data['categoryId'] as String? ?? '',
      isPercentage: data['isPercentage'] as bool? ?? false,
      value: (data['value'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      lastGeneratedPeriod: data['lastGeneratedPeriod'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'categoryId': categoryId,
      'isPercentage': isPercentage,
      'value': value,
      'isActive': isActive,
      // Only "monthly" is supported today, same rationale as BudgetModel.
      'frequency': 'monthly',
      'lastGeneratedPeriod': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'name': name,
      'type': type.name,
      'categoryId': categoryId,
      'isPercentage': isPercentage,
      'value': value,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        id, userId, name, type, categoryId, isPercentage, value,
        isActive, lastGeneratedPeriod, createdAt, updatedAt,
      ];
}
