import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance_app/core/utils/currency_formatter.dart';

void main() {
  // id_ID locale data must be initialized once before NumberFormat with
  // that locale is used, same as main.dart does at app startup.
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('CurrencyFormatter.format', () {
    test('formats a large amount with dot thousand separators and Rp prefix', () {
      expect(CurrencyFormatter.format(5700000), 'Rp5.700.000');
    });

    test('formats a small amount', () {
      expect(CurrencyFormatter.format(100000), 'Rp100.000');
    });

    test('formats zero', () {
      expect(CurrencyFormatter.format(0), 'Rp0');
    });

    test('never shows a raw unformatted number (e.g. no "5700000")', () {
      final result = CurrencyFormatter.format(5700000);
      expect(result, isNot(contains('5700000')));
    });
  });

  group('CurrencyFormatter.formatForInput', () {
    test('formats without the Rp prefix, for pre-filling edit fields', () {
      expect(CurrencyFormatter.formatForInput(35000), '35.000');
    });
  });
}
