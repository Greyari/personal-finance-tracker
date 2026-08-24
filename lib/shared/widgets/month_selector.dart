import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/selected_month_provider.dart';

/// Prev/next month navigator bound to [selectedMonthProvider]. Used by
/// Dashboard, Transaksi, and Budget so all three always agree on which
/// month is being viewed.
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final label = DateFormat.yMMMM('id_ID').format(month);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1),
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1),
          ),
        ],
      ),
    );
  }
}
