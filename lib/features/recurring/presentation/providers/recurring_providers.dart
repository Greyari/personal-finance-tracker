import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/transaction_type.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../data/repositories/recurring_transaction_repository.dart';

final recurringRepositoryProvider = Provider<RecurringTransactionRepository>((ref) {
  return RecurringTransactionRepository();
});

final recurringTransactionsProvider = StreamProvider<List<RecurringTransactionModel>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return Stream.value(const []);
  return ref.watch(recurringRepositoryProvider).watchRecurring(userId);
});

class RecurringController extends StateNotifier<AsyncValue<void>> {
  final RecurringTransactionRepository _repository;
  final String? _userId;

  RecurringController(this._repository, this._userId) : super(const AsyncValue.data(null));

  Future<bool> addRecurring(RecurringTransactionModel recurring) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.addRecurring(recurring);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateRecurring(RecurringTransactionModel recurring) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRecurring(recurring);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteRecurring(String recurringId) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteRecurring(userId: _userId, recurringId: recurringId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setActive(String recurringId, bool isActive) async {
    if (_userId == null) return false;
    try {
      await _repository.setActive(userId: _userId, recurringId: recurringId, isActive: isActive);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final recurringControllerProvider =
    StateNotifierProvider<RecurringController, AsyncValue<void>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  return RecurringController(ref.watch(recurringRepositoryProvider), userId);
});

/// Runs once per (user, app-open) combination — deliberately tied to the
/// *real* current month, NOT selectedMonthProvider, since recurring
/// generation must only ever target the actual current month regardless
/// of which month the user happens to be browsing elsewhere in the app.
/// Watched from MainShell so it fires as soon as the user is signed in.
final recurringGenerationProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return 0;

  final now = DateTime.now();
  final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  final transactionRepo = ref.read(transactionRepositoryProvider);
  final currentMonthTransactions = await transactionRepo
      .watchTransactionsForMonth(userId, year: now.year, month: now.month)
      .first;
  final income = currentMonthTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  return ref.read(recurringRepositoryProvider).generateForPeriodIfNeeded(
        userId: userId,
        period: period,
        monthlyIncome: income,
      );
});
