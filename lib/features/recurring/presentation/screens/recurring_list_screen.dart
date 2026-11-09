import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../providers/recurring_providers.dart';
import 'add_edit_recurring_screen.dart';

class RecurringListScreen extends ConsumerWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final recurringAsync = ref.watch(recurringTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider(null));
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          'Transaksi Berulang',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: recurringAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        size: 48,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada transaksi berulang.\nTekan tombol di bawah untuk menambahkan (misal: Tagihan Listrik, Internet bulanan).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final categories = categoriesAsync.value ?? const [];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final r = items[index];
              final matches = categories.where((c) => c.id == r.categoryId);
              final category = matches.isNotEmpty ? matches.first : null;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  borderRadius: 18,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddEditRecurringScreen(recurring: r)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                        ),
                        child: Icon(
                          CategoryIcons.resolve(category?.icon ?? 'other'),
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r.isPercentage
                                  ? '${r.value.toStringAsFixed(0)}% dari pendapatan · Bulanan'
                                  : 'Nominal tetap · Bulanan',
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: r.isActive,
                        activeThumbColor: primaryColor,
                        onChanged: (value) =>
                            ref.read(recurringControllerProvider.notifier).setActive(r.id, value),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
                    duration: 250.ms,
                  );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
      floatingActionButton: GlassCircularFab(
        heroTag: 'fab_add_recurring',
        bottomMargin: 12,
        tooltip: 'Transaksi Berulang Baru',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditRecurringScreen()),
        ),
      ),
    );
  }
}
