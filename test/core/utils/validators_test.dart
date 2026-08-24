import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/core/utils/validators.dart';

void main() {
  group('Validators.amount', () {
    test('rejects empty input', () {
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount(null), isNotNull);
    });

    test('rejects zero (business rule: amount must be > 0)', () {
      expect(Validators.amount('0'), isNotNull);
    });

    test('accepts a formatted positive amount', () {
      expect(Validators.amount('35.000'), isNull);
    });

    test('accepts a plain positive integer string', () {
      expect(Validators.amount('5700000'), isNull);
    });
  });

  group('Validators.nonNegativeAmount', () {
    test('accepts zero (e.g. investment value after a total loss)', () {
      expect(Validators.nonNegativeAmount('0'), isNull);
    });

    test('rejects empty input', () {
      expect(Validators.nonNegativeAmount(''), isNotNull);
    });

    test('accepts a positive formatted amount', () {
      expect(Validators.nonNegativeAmount('502.000'), isNull);
    });
  });

  group('Validators.percentage', () {
    test('rejects 0%', () {
      expect(Validators.percentage('0'), isNotNull);
    });

    test('rejects values above 100', () {
      expect(Validators.percentage('101'), isNotNull);
    });

    test('accepts 10 (e.g. Gereja 10%)', () {
      expect(Validators.percentage('10'), isNull);
    });

    test('accepts 100 as the upper boundary', () {
      expect(Validators.percentage('100'), isNull);
    });

    test('accepts a comma decimal (Indonesian input style)', () {
      expect(Validators.percentage('12,5'), isNull);
    });
  });

  group('Validators.email', () {
    test('rejects malformed email', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts a well-formed email', () {
      expect(Validators.email('user@example.com'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects mismatched confirmation', () {
      expect(Validators.confirmPassword('abc123', 'xyz789'), isNotNull);
    });

    test('accepts a matching confirmation', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    });
  });
}
