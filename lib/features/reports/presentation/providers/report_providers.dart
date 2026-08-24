import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class CategoryBreakdownEntry {
  final String categoryName;
  final String categoryIcon;
  final double total;

  const CategoryBreakdownEntry({
    required this.categoryName,
    required this.categoryIcon,
    required this.total,
  });
}

/// Groups this month's transactions by category, largest first — the
/// data behind both the Monthly Report's breakdown list and its simple
/// bar visualization (Section 15).
final categoryBreakdownProvider = Provider<List<CategoryBreakdownEntry>>((ref) {
  final transactions = ref.watch(transactionsForMonthProvider).value ?? const [];
  final categories = ref.watch(categoriesProvider(null)).value ?? const [];

  final totals = <String, double>{};
  for (final t in transactions) {
    totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
  }

  final entries = totals.entries.map((entry) {
    final matches = categories.where((c) => c.id == entry.key);
    final category = matches.isNotEmpty ? matches.first : null;
    return CategoryBreakdownEntry(
      categoryName: category?.name ?? 'Lainnya',
      categoryIcon: category?.icon ?? 'other',
      total: entry.value,
    );
  }).toList();

  entries.sort((a, b) => b.total.compareTo(a.total));
  return entries;
});
