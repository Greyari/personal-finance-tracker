import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/features/budgets/data/models/budget_model.dart';

BudgetModel _nominalBudget(double value) => BudgetModel(
      id: 'b1',
      userId: 'u1',
      categoryId: 'c1',
      isPercentage: false,
      value: value,
    );

BudgetModel _percentageBudget(double percent) => BudgetModel(
      id: 'b2',
      userId: 'u1',
      categoryId: 'c2',
      isPercentage: true,
      value: percent,
    );

void main() {
  group('BudgetModel.resolvedAmount — nominal budgets', () {
    test('ignores monthly income entirely', () {
      final budget = _nominalBudget(300000);
      expect(budget.resolvedAmount(5700000), 300000);
      expect(budget.resolvedAmount(0), 300000);
    });
  });

  group('BudgetModel.resolvedAmount — percentage budgets (e.g. Gereja 10%)', () {
    test('resolves 10% of a Rp5.700.000 income to Rp570.000, matching Section 13\'s example', () {
      final gereja = _percentageBudget(10);
      expect(gereja.resolvedAmount(5700000), 570000);
    });

    test('recomputes automatically when income changes, without editing the budget', () {
      final gereja = _percentageBudget(10);
      expect(gereja.resolvedAmount(5700000), 570000);
      expect(gereja.resolvedAmount(6000000), 600000);
    });

    test('resolves to 0 when there is no income yet this month', () {
      final gereja = _percentageBudget(10);
      expect(gereja.resolvedAmount(0), 0);
    });

    test('a 100% budget equals the full income', () {
      final budget = _percentageBudget(100);
      expect(budget.resolvedAmount(1000000), 1000000);
    });
  });
}
