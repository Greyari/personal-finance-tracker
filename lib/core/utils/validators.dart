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

  /// Enforces the business rule "amount transaksi harus lebih besar dari
  /// 0". Accepts a currency-formatted string (e.g. "35.000") since that's
  /// what the amount field actually contains while the user is typing.
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah tidak boleh kosong.';
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return 'Jumlah tidak valid.';
    }
    final parsed = int.tryParse(digitsOnly);
    if (parsed == null || parsed <= 0) {
      return 'Jumlah harus lebih besar dari 0.';
    }
    return null;
  }

  /// Like [amount] but allows zero. Some fields legitimately can be
  /// zero — e.g. an investment's current value after a total loss —
  /// unlike a transaction/budget amount which is meaningless at zero.
  static String? nonNegativeAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah tidak boleh kosong.';
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return 'Jumlah tidak valid.';
    }
    return null;
  }

  /// For percentage-based budgets (e.g. "Gereja 10%"): must be a number
  /// strictly between 0 and 100.
  static String? percentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Persentase tidak boleh kosong.';
    }
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) {
      return 'Persentase tidak valid.';
    }
    if (parsed <= 0 || parsed > 100) {
      return 'Persentase harus antara 0 dan 100.';
    }
    return null;
  }
}
