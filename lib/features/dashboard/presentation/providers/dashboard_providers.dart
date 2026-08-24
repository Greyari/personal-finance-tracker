import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/providers/selected_month_provider.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

/// Section 8 of the spec: this month's totals, computed live from
/// transactions — never hardcoded, never stored separately from the
/// transactions that produce them.
class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double totalSaving;
  final double totalInvestment;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSaving,
    required this.totalInvestment,
  });

  /// "Sisa" — money not yet spent, saved, or invested this month.
  double get sisa => totalIncome - totalExpense - totalSaving - totalInvestment;

  double get savingRate => totalIncome <= 0 ? 0 : (totalSaving / totalIncome) * 100;
  double get investmentRate => totalIncome <= 0 ? 0 : (totalInvestment / totalIncome) * 100;
  double get expenseRate => totalIncome <= 0 ? 0 : (totalExpense / totalIncome) * 100;
}

final monthlySummaryProvider = Provider<MonthlySummary>((ref) {
  final transactions = ref.watch(transactionsForMonthProvider).value ?? const [];

  double sumOf(TransactionType type) => transactions
      .where((t) => t.type == type)
      .fold(0.0, (sum, t) => sum + t.amount);

  return MonthlySummary(
    totalIncome: sumOf(TransactionType.income),
    totalExpense: sumOf(TransactionType.expense),
    totalSaving: sumOf(TransactionType.saving),
    totalInvestment: sumOf(TransactionType.investment),
  );
});

/// "Persentase budget terpakai": total spent vs total budgeted, counting
/// only *expense*-category budgets — saving/investment budgets are
/// allocations the user chooses to make, not a spending cap, so they're
/// excluded from this particular percentage.
final budgetUsedPercentProvider = Provider<double>((ref) {
  final expenseBudgets = ref
      .watch(budgetProgressListProvider)
      .where((p) => p.budget.isActive && p.categoryType == TransactionType.expense);

  final totalBudgeted = expenseBudgets.fold(0.0, (sum, p) => sum + p.resolvedAmount);
  final totalSpent = expenseBudgets.fold(0.0, (sum, p) => sum + p.spentAmount);
  if (totalBudgeted <= 0) return 0;
  return (totalSpent / totalBudgeted) * 100;
});

/// Section 10: "Batas pengeluaran hari ini" — remaining expense budget
/// divided by remaining days in the month. Only meaningful for the
/// month that's actually in progress; browsing a past or future month
/// returns null and the UI hides the card rather than showing a
/// misleading number.
final dailySpendingLimitProvider = Provider<double?>((ref) {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final now = DateTime.now();
  final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
  if (!isCurrentMonth) return null;

  final expenseBudgets = ref
      .watch(budgetProgressListProvider)
      .where((p) => p.budget.isActive && p.categoryType == TransactionType.expense);

  final totalBudgeted = expenseBudgets.fold(0.0, (sum, p) => sum + p.resolvedAmount);
  final totalSpent = expenseBudgets.fold(0.0, (sum, p) => sum + p.spentAmount);
  final remaining = totalBudgeted - totalSpent;

  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final daysRemaining = daysInMonth - now.day + 1; // inclusive of today
  if (daysRemaining <= 0) return 0;

  return remaining > 0 ? remaining / daysRemaining : 0;
});
