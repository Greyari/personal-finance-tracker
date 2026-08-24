import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The month currently being viewed. Shared across Dashboard, Transaksi,
/// and Budget so navigating to a different month in one tab is reflected
/// in the others too. Defaults to the current calendar month.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});
