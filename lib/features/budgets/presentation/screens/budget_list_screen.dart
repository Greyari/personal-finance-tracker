import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../providers/budget_providers.dart';
import 'add_edit_budget_screen.dart';

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final progressList = ref.watch(budgetProgressListProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final totalActiveBudget = ref.watch(totalActiveBudgetProvider);
    final isOverBudget = income > 0 && totalActiveBudget > income;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: budgetsAsync.when(
        data: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MonthSelector(),
            const SizedBox(height: 8),
            _TotalBudgetCard(
              totalBudget: totalActiveBudget,
              income: income,
              isOver: isOverBudget,
            ),
            const SizedBox(height: 16),
            if (progressList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Belum ada budget.\nTekan tombol + untuk membuat budget pertama Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...progressList.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BudgetProgressTile(progress: p),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditBudgetScreen()),
        ),
        child: const Icon(Icons.add),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOver ? AppColors.error : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Budget Aktif', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(totalBudget),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'dari pendapatan ${CurrencyFormatter.format(income)} bulan ini',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (isOver) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Total budget melebihi pendapatan bulan ini.',
                    style: TextStyle(color: AppColors.error, fontSize: 13),
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

class _BudgetProgressTile extends ConsumerWidget {
  final BudgetProgress progress;
  const _BudgetProgressTile({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = progress.percent;
    final displayPercent = (percent * 100).clamp(0, 999).toStringAsFixed(0);

    final Color barColor;
    final String? statusText;
    if (percent >= 1.0) {
      barColor = AppColors.error;
      statusText = '🔴 Budget ${progress.categoryName} sudah terlampaui.';
    } else if (percent >= 0.8) {
      barColor = AppColors.warning;
      statusText = '⚠️ Budget ${progress.categoryName} hampir habis.';
    } else {
      barColor = AppColors.success;
      statusText = null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.background,
                child: Icon(CategoryIcons.resolve(progress.categoryIcon)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(progress.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      progress.budget.isPercentage
                          ? '${progress.budget.value.toStringAsFixed(0)}% dari pendapatan'
                          : 'Nominal tetap'
                              '${progress.budget.isActive ? '' : ' · Nonaktif'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: progress.budget.isActive,
                onChanged: (value) => ref
                    .read(budgetControllerProvider.notifier)
                    .setActive(progress.budget.id, value),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => AddEditBudgetScreen(budget: progress.budget)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${CurrencyFormatter.format(progress.spentAmount)} / ${CurrencyFormatter.format(progress.resolvedAmount)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.background,
              color: barColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$displayPercent%',
            style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (statusText != null) ...[
            const SizedBox(height: 6),
            Text(statusText, style: TextStyle(color: barColor, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
