import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter that live-formats digits typed into an amount
/// field with Indonesian thousand separators, e.g. typing "35000" shows
/// "35.000" as the user types. Pair with [parse] to get the raw number
/// back out when saving.
class CurrencyInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final value = int.parse(digitsOnly);
    final newText = _formatter.format(value);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  /// Strips formatting back to a raw double, e.g. "35.000" -> 35000.0
  static double parse(String formatted) {
    final digitsOnly = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return 0;
    return double.parse(digitsOnly);
  }
}
