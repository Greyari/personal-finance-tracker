import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/app_user_model.dart';

/// Reads/writes the user profile document at users/{userId}/profile/data.
///
/// Every method takes an explicit userId and only ever touches that
/// user's document — this is the repository-level half of the
/// "user can only access their own data" rule. The other half is
/// enforced server-side by firestore.rules, so a compromised client
/// still can't read someone else's data.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _profileDoc(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection(FirestoreCollections.profile)
        .doc(FirestoreCollections.profileDocId);
  }

  Future<void> createProfile(AppUserModel user) async {
    await _profileDoc(user.userId).set(user.toMapForCreate());
  }

  Future<AppUserModel?> getProfile(String userId) async {
    final snapshot = await _profileDoc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AppUserModel.fromMap(userId, snapshot.data()!);
  }

  /// Real-time profile stream, used by the Riverpod provider so the UI
  /// updates automatically if the profile changes (e.g. edited in Settings
  /// in a later phase).
  Stream<AppUserModel?> watchProfile(String userId) {
    return _profileDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return AppUserModel.fromMap(userId, snapshot.data()!);
    });
  }

  Future<void> updateProfile(AppUserModel user) async {
    await _profileDoc(user.userId).update(user.toMapForUpdate());
  }
}
