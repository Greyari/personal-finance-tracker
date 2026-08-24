import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/transaction_type.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';

class MonthProjection {
  final int monthIndex; // 1-6
  final double income;
  final double saving;
  final double investment;

  const MonthProjection({
    required this.monthIndex,
    required this.income,
    required this.saving,
    required this.investment,
  });
}

class SixMonthProjection {
  final List<MonthProjection> months;
  final double totalSavingTarget;
  final double totalInvestmentTarget;

  const SixMonthProjection({
    required this.months,
    required this.totalSavingTarget,
    required this.totalInvestmentTarget,
  });

  double get totalAssetTarget => totalSavingTarget + totalInvestmentTarget;
}

/// Section 16: projects the next 6 months assuming the user keeps their
/// current income and active budget commitments constant (a reasonable
/// baseline given "user mempunyai kontrak kerja selama 6 bulan").
///
/// Deliberately uses the BUDGET plan (saving/investment-type budgets),
/// not just this month's actual transactions, for saving/investment —
/// a projection is forward-looking by nature, so it should reflect what
/// the user has committed to, not only what happened to occur this
/// month. Every number here traces back to either recorded income or an
/// active budget; nothing is a fixed constant.
final sixMonthProjectionProvider = Provider<SixMonthProjection>((ref) {
  final income = ref.watch(monthlyIncomeProvider);
  final progress = ref.watch(budgetProgressListProvider).where((p) => p.budget.isActive);

  final monthlySaving = progress
      .where((p) => p.categoryType == TransactionType.saving)
      .fold(0.0, (sum, p) => sum + p.resolvedAmount);
  final monthlyInvestment = progress
      .where((p) => p.categoryType == TransactionType.investment)
      .fold(0.0, (sum, p) => sum + p.resolvedAmount);

  final months = List.generate(
    6,
    (i) => MonthProjection(
      monthIndex: i + 1,
      income: income,
      saving: monthlySaving,
      investment: monthlyInvestment,
    ),
  );

  return SixMonthProjection(
    months: months,
    totalSavingTarget: monthlySaving * 6,
    totalInvestmentTarget: monthlyInvestment * 6,
  );
});
