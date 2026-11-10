import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a document at users/{userId}/saving_goals/{goalId}.
///
/// `currentAmount` is a running total kept in sync with the goal's
/// `contributions` subcollection — see SavingGoalRepository.addContribution,
/// which increments it atomically whenever a contribution is recorded, so
/// it can never drift out of sync with the contribution history.
class SavingGoalModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  /// Local file path (app documents dir) of the user-picked cover photo.
  final String? coverImagePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SavingGoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.coverImagePath,
    this.createdAt,
    this.updatedAt,
  });

  double get progress => targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
  bool get isAchieved => targetAmount > 0 && currentAmount >= targetAmount;

  factory SavingGoalModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SavingGoalModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0,
      coverImagePath: data['coverImagePath'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'userId': userId,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': 0,
      'coverImagePath': coverImagePath,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'coverImagePath': coverImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, name, targetAmount, currentAmount, coverImagePath, createdAt, updatedAt];
}
