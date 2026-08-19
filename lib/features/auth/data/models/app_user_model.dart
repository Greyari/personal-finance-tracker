import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents the user's profile document, stored at:
///   users/{userId}/profile/data
///
/// Note: this is separate from FirebaseAuth's `User` object. FirebaseAuth
/// owns identity (email/password/uid); Firestore owns app-specific profile
/// data. Keeping them separate lets us add fields later (e.g. currency
/// preference, church donation %) without touching auth at all.
class AppUserModel extends Equatable {
  final String userId;
  final String email;
  final String displayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUserModel.fromMap(String userId, Map<String, dynamic> map) {
    return AppUserModel(
      userId: userId,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Uses serverTimestamp for both fields on creation, per the
  /// "use consistent server timestamps" business rule.
  Map<String, dynamic> toMapForCreate() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'email': email,
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppUserModel copyWith({String? displayName}) {
    return AppUserModel(
      userId: userId,
      email: email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [userId, email, displayName, createdAt, updatedAt];
}
