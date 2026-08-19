/// Shared form validators. Kept in core/utils so later phases
/// (transaction amount, budget nominal, etc.) can reuse the same
/// validation style instead of re-inventing it per feature.
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong.';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong.';
    }
    if (value != password) {
      return 'Konfirmasi password tidak sama.';
    }
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong.';
    }
    if (value.trim().length < 2) {
      return 'Nama terlalu pendek.';
    }
    return null;
  }
}
