import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a document at
/// users/{userId}/saving_goals/{goalId}/contributions/{contributionId}.
/// One entry per "+ Rp2.500.000 Tabungan bulanan" style addition (Section
/// 11). Contributions are additions only — there's no withdrawal flow in
/// this phase since the spec doesn't ask for one.
class GoalContributionModel extends Equatable {
  final String id;
  final double amount;
  final String note;
  final DateTime date;
  final DateTime? createdAt;

  const GoalContributionModel({
    required this.id,
    required this.amount,
    required this.note,
    required this.date,
    this.createdAt,
  });

  factory GoalContributionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GoalContributionModel(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      note: data['note'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, amount, note, date, createdAt];
}
