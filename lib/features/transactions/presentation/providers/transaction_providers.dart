import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/selected_month_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

// Re-exported so existing imports of this file (e.g. transaction_list_screen)
// keep working without needing to also import the shared provider directly.
export '../../../../shared/providers/selected_month_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Re-queries automatically whenever the signed-in user or the selected
/// month changes.
final transactionsForMonthProvider = StreamProvider<List<TransactionModel>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  final month = ref.watch(selectedMonthProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(transactionRepositoryProvider).watchTransactionsForMonth(
        userId,
        year: month.year,
        month: month.month,
      );
});

class TransactionController extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;
  final String? _userId;

  TransactionController(this._repository, this._userId)
      : super(const AsyncValue.data(null));

  Future<String?> addTransaction(TransactionModel transaction) async {
    if (_userId == null) return null;
    state = const AsyncValue.loading();
    try {
      final docId = await _repository.addTransaction(transaction);
      state = const AsyncValue.data(null);
      return docId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTransaction(transaction);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTransaction(userId: _userId, transactionId: transactionId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, AsyncValue<void>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  return TransactionController(ref.watch(transactionRepositoryProvider), userId);
});
