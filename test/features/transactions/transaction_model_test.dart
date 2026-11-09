import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/features/transactions/data/models/transaction_model.dart';
import 'package:personal_finance_app/shared/models/transaction_type.dart';

void main() {
  group('TransactionModel & TransactionType', () {
    test('identifies income and expense correctly', () {
      final incomeTx = TransactionModel(
        id: 't1',
        userId: 'u1',
        type: TransactionType.income,
        categoryId: 'c_gaji',
        amount: 5000000,
        description: 'Gaji Bulanan',
        date: DateTime(2026, 11, 1),
      );

      final expenseTx = TransactionModel(
        id: 't2',
        userId: 'u1',
        type: TransactionType.expense,
        categoryId: 'c_makan',
        amount: 50000,
        description: 'Makan siang',
        date: DateTime(2026, 11, 2),
      );

      expect(incomeTx.isIncome, isTrue);
      expect(incomeTx.isExpense, isFalse);
      expect(incomeTx.type.subtitle, 'Uang Masuk');

      expect(expenseTx.isIncome, isFalse);
      expect(expenseTx.isExpense, isTrue);
      expect(expenseTx.type.subtitle, 'Uang Keluar');
    });

    test('toMapForCreate includes required fields', () {
      final tx = TransactionModel(
        id: 't1',
        userId: 'u1',
        type: TransactionType.income,
        categoryId: 'c1',
        amount: 150000,
        description: 'Freelance',
        date: DateTime(2026, 11, 5),
      );

      final map = tx.toMapForCreate();
      expect(map['userId'], 'u1');
      expect(map['type'], 'income');
      expect(map['amount'], 150000);
      expect(map['description'], 'Freelance');
      expect(map['categoryId'], 'c1');
    });
  });
}
