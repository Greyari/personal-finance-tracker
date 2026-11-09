import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../providers/selected_month_provider.dart';
import 'glass_widgets.dart';

/// Glassmorphic month selector with interactive dropdown picker.
/// No swiping back and forth needed — direct 1-tap month selection.
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedMonthProvider);
    final isDark = AppColors.isDark(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final now = DateTime.now();
    final isCurrentMonth = selected.year == now.year && selected.month == now.month;

    // Generate selectable months dynamically from 3 years ago up to 4 years ahead (e.g. 2023 - 2030+)
    final months = <DateTime>[];
    for (int y = now.year - 3; y <= now.year + 4; y++) {
      for (int m = 1; m <= 12; m++) {
        months.add(DateTime(y, m));
      }
    }
    if (!months.any((d) => d.year == selected.year && d.month == selected.month)) {
      months.add(DateTime(selected.year, selected.month));
      months.sort((a, b) => a.compareTo(b));
    }

    final normalizedSelected = months.firstWhere(
      (d) => d.year == selected.year && d.month == selected.month,
      orElse: () => months.first,
    );

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateTime>(
                value: normalizedSelected,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: primaryColor,
                  size: 22,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                items: months.map((d) {
                  final isCurrent = d.year == now.year && d.month == now.month;
                  final label = DateFormat.yMMMM('id_ID').format(d);
                  return DropdownMenuItem<DateTime>(
                    value: d,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Bulan Ini',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newDate) {
                  if (newDate != null) {
                    ref.read(selectedMonthProvider.notifier).state = newDate;
                  }
                },
              ),
            ),
          ),
          if (!isCurrentMonth) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => ref.read(selectedMonthProvider.notifier).state =
                  DateTime(now.year, now.month),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.today_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Bulan Ini',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
