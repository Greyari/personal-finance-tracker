import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/features/dashboard/presentation/providers/dashboard_providers.dart';

void main() {
  group('MonthlySummary calculations', () {
    test('computes sisa and netCashFlow accurately', () {
      const summary = MonthlySummary(
        totalIncome: 10000000,
        totalExpense: 4000000,
        totalSaving: 2000000,
        totalInvestment: 1000000,
      );

      // totalOutflow = expense + saving + investment
      expect(summary.totalOutflow, 7000000);
      // netCashFlow = sisa = income - totalOutflow
      expect(summary.netCashFlow, 3000000);
      // sisa = income - expense - saving - investment
      expect(summary.sisa, 3000000);
      expect(summary.savingRate, 20.0);
      expect(summary.investmentRate, 10.0);
      expect(summary.expenseRate, 40.0);
    });

    test('handles zero income safely without divide-by-zero', () {
      const summary = MonthlySummary(
        totalIncome: 0,
        totalExpense: 500000,
        totalSaving: 0,
        totalInvestment: 0,
      );

      expect(summary.netCashFlow, -500000);
      expect(summary.sisa, -500000);
      expect(summary.savingRate, 0.0);
      expect(summary.investmentRate, 0.0);
      expect(summary.expenseRate, 0.0);
    });
  });
}
