import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../providers/budget_providers.dart';
import 'add_edit_budget_screen.dart';

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final budgetsAsync = ref.watch(budgetsProvider);
    final progressList = ref.watch(budgetProgressListProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final totalActiveBudget = ref.watch(totalActiveBudgetProvider);
    final isOverBudget = income > 0 && totalActiveBudget > income;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Alokasi Budget',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          GlassSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(budgetsProvider);
              await Future<void>.delayed(const Duration(milliseconds: 600));
            },
          ),
          budgetsAsync.when(
            skipLoadingOnRefresh: true,
            data: (_) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const MonthSelector().animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  _TotalBudgetCard(
                    totalBudget: totalActiveBudget,
                    income: income,
                    isOver: isOverBudget,
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 18),
                  if (progressList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pie_chart_outline_rounded,
                                size: 48,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada budget untuk pos pengeluaran.\nTekan tombol di bawah untuk membuat budget pertama.',
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
                    ).animate().fadeIn(duration: 400.ms)
                  else
                    ...progressList.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final p = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BudgetProgressTile(progress: p),
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 40 * index.clamp(0, 10)),
                              duration: 250.ms,
                            );
                      },
                    ),
                ]),
              ),
            ),
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Terjadi kesalahan: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: GlassCircularFab(
        heroTag: 'fab_add_budget',
        tooltip: 'Tambah Budget',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditBudgetScreen()),
        ),
      ),
    );
  }
}

class _TotalBudgetCard extends StatelessWidget {
  final double totalBudget;
  final double income;
  final bool isOver;

  const _TotalBudgetCard({
    required this.totalBudget,
    required this.income,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final expenseColor = AppColors.expense(context);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Budget Aktif',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              if (isOver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: expenseColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: expenseColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: expenseColor),
                      const SizedBox(width: 4),
                      Text(
                        'Over Budget',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: expenseColor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(totalBudget),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            income > 0
                ? 'dari total pendapatan ${CurrencyFormatter.format(income)} bulan ini'
                : 'Belum ada catatan pendapatan bulan ini',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetProgressTile extends ConsumerWidget {
  final BudgetProgress progress;
  const _BudgetProgressTile({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final percent = progress.percent;
    final displayPercent = (percent * 100).clamp(0, 999).toStringAsFixed(0);

    final Color barColor;
    final String? statusText;
    if (percent >= 1.0) {
      barColor = AppColors.expense(context);
      statusText = 'Budget ${progress.categoryName} sudah terlampaui';
    } else if (percent >= 0.8) {
      barColor = isDark ? AppColors.warningDark : AppColors.warningLight;
      statusText = 'Budget ${progress.categoryName} hampir habis';
    } else {
      barColor = AppColors.income(context);
      statusText = null;
    }

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: barColor.withValues(alpha: 0.25), width: 1),
                ),
                child: Icon(
                  CategoryIcons.resolve(progress.categoryIcon),
                  color: barColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.categoryName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progress.budget.isPercentage
                          ? '${progress.budget.value.toStringAsFixed(0)}% dari pendapatan'
                          : 'Nominal tetap${progress.budget.isActive ? '' : ' · Nonaktif'}',
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: progress.budget.isActive,
                activeThumbColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                onChanged: (value) => ref
                    .read(budgetControllerProvider.notifier)
                    .setActive(progress.budget.id, value),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 19),
                tooltip: 'Edit Budget',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditBudgetScreen(budget: progress.budget),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(progress.spentAmount)} / ${CurrencyFormatter.format(progress.resolvedAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '$displayPercent%',
                style: TextStyle(
                  color: barColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 7,
              backgroundColor: isDark ? const Color(0x33FFFFFF) : const Color(0x1F0F172A),
              color: barColor,
            ),
          ),
          if (statusText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  percent >= 1.0 ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                  size: 14,
                  color: barColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
