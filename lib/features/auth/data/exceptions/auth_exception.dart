/// App-level auth exception. UI code catches this instead of
/// FirebaseAuthException directly, so the presentation layer never needs
/// to know about Firebase error codes.
class AppAuthException implements Exception {
  final String code;
  final String message;

  const AppAuthException(this.code, this.message);

  @override
  String toString() => message;
}

/// Translates FirebaseAuth error codes into user-friendly Indonesian
/// messages. Centralized here so every screen shows consistent wording.
class AuthExceptionMapper {
  AuthExceptionMapper._();

  static AppAuthException map(String code) {
    switch (code) {
      case 'invalid-email':
        return const AppAuthException(
            'invalid-email', 'Format email tidak valid.');
      case 'user-disabled':
        return const AppAuthException(
            'user-disabled', 'Akun ini telah dinonaktifkan.');
      case 'user-not-found':
        return const AppAuthException(
            'user-not-found', 'Akun tidak ditemukan.');
      case 'wrong-password':
        return const AppAuthException('wrong-password', 'Password salah.');
      case 'email-already-in-use':
        return const AppAuthException(
            'email-already-in-use', 'Email sudah terdaftar.');
      case 'weak-password':
        return const AppAuthException(
            'weak-password', 'Password terlalu lemah, minimal 6 karakter.');
      case 'invalid-credential':
        return const AppAuthException(
            'invalid-credential', 'Email atau password salah.');
      case 'too-many-requests':
        return const AppAuthException(
            'too-many-requests', 'Terlalu banyak percobaan. Coba lagi nanti.');
      case 'network-request-failed':
        return const AppAuthException(
            'network-request-failed', 'Tidak ada koneksi internet.');
      default:
        return AppAuthException(code, 'Terjadi kesalahan. Silakan coba lagi.');
    }
  }
}
