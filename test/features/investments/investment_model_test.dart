import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/features/investments/data/models/investment_model.dart';

void main() {
  group('InvestmentModel profit/return', () {
    test('matches Section 12\'s own example: Rp500.000 -> Rp502.000 is +Rp2.000, 0.4%', () {
      final investment = InvestmentModel(
        id: 'i1',
        userId: 'u1',
        categoryId: 'c1',
        name: 'Reksa Dana',
        capital: 500000,
        currentValue: 502000,
        date: DateTime(2026, 8, 19),
      );

      expect(investment.profit, 2000);
      expect(investment.returnPercent, closeTo(0.4, 0.001));
    });

    test('a loss produces a negative profit and negative return %', () {
      final investment = InvestmentModel(
        id: 'i2',
        userId: 'u1',
        categoryId: 'c1',
        name: 'Saham XYZ',
        capital: 1000000,
        currentValue: 800000,
        date: DateTime(2026, 8, 19),
      );

      expect(investment.profit, -200000);
      expect(investment.returnPercent, -20);
    });

    test('a total loss (currentValue 0) is representable without dividing by zero', () {
      final investment = InvestmentModel(
        id: 'i3',
        userId: 'u1',
        categoryId: 'c1',
        name: 'Crypto',
        capital: 100000,
        currentValue: 0,
        date: DateTime(2026, 8, 19),
      );

      expect(investment.profit, -100000);
      expect(investment.returnPercent, -100);
    });

    test('zero capital never causes a divide-by-zero in returnPercent', () {
      final investment = InvestmentModel(
        id: 'i4',
        userId: 'u1',
        categoryId: 'c1',
        name: 'Edge case',
        capital: 0,
        currentValue: 0,
        date: DateTime(2026, 8, 19),
      );

      expect(investment.returnPercent, 0);
    });
  });
}
