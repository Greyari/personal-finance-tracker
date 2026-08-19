import 'package:firebase_auth/firebase_auth.dart';

import '../exceptions/auth_exception.dart';

/// Thin wrapper around FirebaseAuth. Isolating Firebase calls here means:
///   - the rest of the app never imports firebase_auth directly
///   - this class can be mocked/faked in widget tests
///   - swapping identity providers later only touches this one file
class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User> signIn(
      {required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppAuthException(
            'unknown', 'Login gagal. Silakan coba lagi.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.map(e.code);
    }
  }

  Future<User> register(
      {required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppAuthException(
            'unknown', 'Registrasi gagal. Silakan coba lagi.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.map(e.code);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthExceptionMapper.map(e.code);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
