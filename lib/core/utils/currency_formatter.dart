import 'package:intl/intl.dart';

/// Formats numbers as Indonesian Rupiah — "Rp5.700.000", never a raw
/// number like "5700000". Used anywhere a money amount is displayed.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  /// For display: "Rp5.700.000"
  static String format(num amount) => 'Rp${_formatter.format(amount)}';

  /// For pre-filling an editable amount field (no "Rp" prefix, since the
  /// field already shows one via its hint/label): "5.700.000"
  static String formatForInput(num amount) => _formatter.format(amount);
}
