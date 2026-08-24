import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/transaction_type.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

/// A user's budgets are a standing monthly plan, not stored per-month —
/// so this simply streams every budget document, independent of
/// [selectedMonthProvider]. What changes month to month is how much of
/// each budget has been spent, computed in [budgetProgressListProvider].
final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return Stream.value(const []);
  return ref.watch(budgetRepositoryProvider).watchBudgets(userId);
});

/// Total income for the currently selected month — the base that
/// percentage-based budgets resolve against, and what the dashboard's
/// saving/investment rate percentages are computed from.
final monthlyIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsForMonthProvider).value ?? const [];
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// One budget, resolved against the selected month: how much was
/// budgeted (after resolving nominal/percentage), how much was actually
/// spent in that category this month, and the category's display info.
class BudgetProgress {
  final BudgetModel budget;
  final String categoryName;
  final String categoryIcon;
  final TransactionType categoryType;
  final double resolvedAmount;
  final double spentAmount;

  const BudgetProgress({
    required this.budget,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryType,
    required this.resolvedAmount,
    required this.spentAmount,
  });

  /// 0.0–1.0+ (can exceed 1.0 when over budget). Guards against
  /// division by zero for a budget resolved to Rp0.
  double get percent => resolvedAmount <= 0 ? 0 : spentAmount / resolvedAmount;
}

/// Combines budgets + this month's transactions + categories into a
/// ready-to-render list. This is the single source of truth the Budget
/// screen's progress bars and the Dashboard's "budget used %" both read
/// from, so they can never disagree with each other.
final budgetProgressListProvider = Provider<List<BudgetProgress>>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? const [];
  final transactions = ref.watch(transactionsForMonthProvider).value ?? const [];
  final categories = ref.watch(categoriesProvider(null)).value ?? const [];
  final income = ref.watch(monthlyIncomeProvider);

  return budgets.map((budget) {
    final matches = categories.where((c) => c.id == budget.categoryId);
    final category = matches.isNotEmpty ? matches.first : null;
    final spent = transactions
        .where((t) => t.categoryId == budget.categoryId)
        .fold(0.0, (sum, t) => sum + t.amount);

    return BudgetProgress(
      budget: budget,
      categoryName: category?.name ?? 'Kategori tidak ditemukan',
      categoryIcon: category?.icon ?? 'other',
      categoryType: category?.type ?? TransactionType.expense,
      resolvedAmount: budget.resolvedAmount(income),
      spentAmount: spent,
    );
  }).toList();
});

/// Sum of every *active* budget's resolved amount, regardless of
/// category type. Used to show "Total Budget Aktif" against income on
/// the Budget screen — this is the "Total tidak boleh melebihi
/// pendapatan" check from Section 5. It's surfaced as a warning banner
/// rather than a hard block, since a personal-finance app shouldn't
/// prevent someone from recording their real (possibly over-committed)
/// plan — it should make the overcommitment visible.
final totalActiveBudgetProvider = Provider<double>((ref) {
  final progress = ref.watch(budgetProgressListProvider);
  return progress
      .where((p) => p.budget.isActive)
      .fold(0.0, (sum, p) => sum + p.resolvedAmount);
});

class BudgetController extends StateNotifier<AsyncValue<void>> {
  final BudgetRepository _repository;
  final String? _userId;

  BudgetController(this._repository, this._userId)
      : super(const AsyncValue.data(null));

  Future<bool> addBudget({
    required String categoryId,
    required bool isPercentage,
    required double value,
  }) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.addBudget(BudgetModel(
        id: '',
        userId: _userId,
        categoryId: categoryId,
        isPercentage: isPercentage,
        value: value,
      ));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateBudget(BudgetModel budget) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBudget(budget);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteBudget(String budgetId) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBudget(userId: _userId, budgetId: budgetId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Doesn't route through the loading/error AsyncValue state, since
  /// this is a quick inline toggle in a list — a full-screen loading
  /// state for it would feel heavy-handed. Errors are swallowed to a
  /// bool so the switch can just snap back if the write failed.
  Future<bool> setActive(String budgetId, bool isActive) async {
    if (_userId == null) return false;
    try {
      await _repository.setActive(
          userId: _userId, budgetId: budgetId, isActive: isActive);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final budgetControllerProvider =
    StateNotifierProvider<BudgetController, AsyncValue<void>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  return BudgetController(ref.watch(budgetRepositoryProvider), userId);
});
