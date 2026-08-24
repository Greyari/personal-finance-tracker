import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps errors from repositories (Firestore exceptions, validation
/// ArgumentErrors) to user-friendly Indonesian messages for snackbars.
///
/// This is the non-auth counterpart to AuthExceptionMapper — Firebase
/// Auth errors already produce Indonesian messages via AppAuthException,
/// but Firestore operations across Transactions, Budgets, Categories,
/// Goals, Investments, and Recurring Transactions all throw raw
/// FirebaseException/ArgumentError, which this centralizes instead of
/// letting each screen show `error.toString()` (English, and often
/// exposes internal detail the user shouldn't need to see).
class ErrorMapper {
  ErrorMapper._();

  static String toUserMessage(Object? error) {
    if (error == null) return 'Terjadi kesalahan. Silakan coba lagi.';

    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Anda tidak memiliki izin untuk melakukan tindakan ini.';
        case 'unavailable':
        case 'network-request-failed':
          return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
        case 'not-found':
          return 'Data tidak ditemukan. Mungkin sudah dihapus di perangkat lain.';
        case 'already-exists':
          return 'Data ini sudah ada.';
        case 'resource-exhausted':
          return 'Terlalu banyak permintaan. Coba lagi sebentar lagi.';
        case 'deadline-exceeded':
        case 'cancelled':
          return 'Permintaan memakan waktu terlalu lama. Coba lagi.';
        default:
          return 'Terjadi kesalahan pada server. Silakan coba lagi.';
      }
    }

    if (error is ArgumentError) {
      // Repository-level validation (amount > 0, percentage <= 100, etc.)
      // — the form validator should normally catch this first, so
      // reaching here means something bypassed it. Show a generic
      // message rather than the internal English ArgumentError text.
      return 'Data yang dimasukkan tidak valid. Periksa kembali sebelum menyimpan.';
    }

    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
