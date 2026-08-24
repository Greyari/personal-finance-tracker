import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a document at users/{userId}/investments/{investmentId}.
/// Manual tracking only — Section 12 explicitly rules out any broker or
/// platform integration for this first version.
class InvestmentModel extends Equatable {
  final String id;
  final String userId;
  final String categoryId; // an Investment-type category, e.g. "Reksa Dana"
  final String name;
  final double capital;
  final double currentValue;
  final DateTime date;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InvestmentModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.capital,
    required this.currentValue,
    required this.date,
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });

  double get profit => currentValue - capital;
  double get returnPercent => capital <= 0 ? 0 : (profit / capital) * 100;

  factory InvestmentModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return InvestmentModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      capital: (data['capital'] as num?)?.toDouble() ?? 0,
      currentValue: (data['currentValue'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'name': name,
      'capital': capital,
      'currentValue': currentValue,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'categoryId': categoryId,
      'name': name,
      'capital': capital,
      'currentValue': currentValue,
      'date': Timestamp.fromDate(date),
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [
        id, userId, categoryId, name, capital, currentValue, date, note, createdAt, updatedAt,
      ];
}
