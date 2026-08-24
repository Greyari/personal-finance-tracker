import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/report_providers.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthlySummaryProvider);
    final breakdown = ref.watch(categoryBreakdownProvider);
    final maxTotal =
        breakdown.isEmpty ? 1.0 : breakdown.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Bulanan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const MonthSelector(),
          const SizedBox(height: 16),
          _TotalsCard(summary: summary),
          const SizedBox(height: 24),
          const Text('Breakdown per Kategori',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          if (breakdown.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Belum ada transaksi bulan ini.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...breakdown.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _BreakdownRow(entry: entry, maxTotal: maxTotal),
                )),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final MonthlySummary summary;
  const _TotalsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _TotalRow(label: 'Total Income', amount: summary.totalIncome, color: AppColors.success),
          const Divider(height: 20),
          _TotalRow(label: 'Total Expense', amount: summary.totalExpense, color: AppColors.error),
          const Divider(height: 20),
          _TotalRow(
              label: 'Total Saving', amount: summary.totalSaving, color: AppColors.primary),
          const Divider(height: 20),
          _TotalRow(
              label: 'Total Investment',
              amount: summary.totalInvestment,
              color: AppColors.primary),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _TotalRow({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(CurrencyFormatter.format(amount),
            style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

/// "Chart sederhana" per Section 15 — a horizontal bar sized relative to
/// the largest category. Deliberately not a charting package: keeps the
/// dependency list small for something this simple.
class _BreakdownRow extends StatelessWidget {
  final CategoryBreakdownEntry entry;
  final double maxTotal;
  const _BreakdownRow({required this.entry, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    final fraction = maxTotal <= 0 ? 0.0 : entry.total / maxTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CategoryIcons.resolve(entry.categoryIcon), size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(child: Text(entry.categoryName, style: const TextStyle(fontSize: 13))),
            Text(CurrencyFormatter.format(entry.total),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.background,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
