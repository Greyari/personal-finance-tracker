import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../../shared/models/transaction_type.dart';

/// Represents a document at users/{userId}/categories/{categoryId}.
class CategoryModel extends Equatable {
  final String id;
  final String name;
  final TransactionType type;
  final String icon;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: TransactionTypeX.fromString(data['type'] as String? ?? 'expense'),
      icon: data['icon'] as String? ?? 'other',
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMapForCreate({bool isDefault = false}) {
    return {
      'name': name,
      'type': type.name,
      'icon': icon,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Type is intentionally not editable — a category switching type
  /// (e.g. Expense -> Income) would silently misclassify every past
  /// transaction that uses it. To recategorize, the user adds a new
  /// category and deletes the old one.
  Map<String, dynamic> toMapForUpdate() {
    return {
      'name': name,
      'icon': icon,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props =>
      [id, name, type, icon, isDefault, createdAt, updatedAt];
}
