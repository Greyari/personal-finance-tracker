import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a document at users/{userId}/budgets/{budgetId}.
///
/// A budget always targets one category. `value` means different things
/// depending on `isPercentage`:
///   - isPercentage == false: `value` IS the budgeted Rupiah amount.
///   - isPercentage == true:  `value` is a percentage (e.g. 10 for 10%)
///     of that month's total income — this is what lets "Gereja 10%"
///     (Section 13) reuse this same model in a later phase instead of
///     needing a separate one.
class BudgetModel extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final bool isPercentage;
  final double value;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.isPercentage,
    required this.value,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Resolves this budget to an actual Rupiah amount for a given month's
  /// total income. Nominal budgets ignore [monthlyIncome] entirely;
  /// percentage budgets are recomputed fresh every time income changes,
  /// per the business rule "Gereja 10% dihitung berdasarkan income
  /// sesuai konfigurasi user".
  double resolvedAmount(double monthlyIncome) {
    if (isPercentage) return monthlyIncome * value / 100;
    return value;
  }

  factory BudgetModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BudgetModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      isPercentage: data['isPercentage'] as bool? ?? false,
      value: (data['value'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'isPercentage': isPercentage,
      'value': value,
      'isActive': isActive,
      // Only "monthly" is supported today; the field exists so a future
      // phase can add weekly/yearly without a schema migration.
      'period': 'monthly',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'categoryId': categoryId,
      'isPercentage': isPercentage,
      'value': value,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, categoryId, isPercentage, value, isActive, createdAt, updatedAt];
}
