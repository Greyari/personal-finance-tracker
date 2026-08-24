import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../reports/presentation/screens/monthly_report_screen.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../providers/dashboard_providers.dart';
import '../providers/financial_health_provider.dart';
import 'financial_health_screen.dart';
import 'six_month_projection_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final transactionsAsync = ref.watch(transactionsForMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final budgetUsedPercent = ref.watch(budgetUsedPercentProvider);
    final dailyLimit = ref.watch(dailySpendingLimitProvider);
    final health = ref.watch(financialHealthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Finance')),
      body: transactionsAsync.when(
        data: (_) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            profileAsync.when(
              data: (profile) => Text(
                'Halo, ${profile?.displayName ?? ''} 👋',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 4),
            const MonthSelector(),
            const SizedBox(height: 12),
            _SummaryGrid(summary: summary),
            const SizedBox(height: 12),
            _SisaCard(sisa: summary.sisa),
            if (dailyLimit != null) ...[
              const SizedBox(height: 12),
              _DailyLimitCard(limit: dailyLimit),
            ],
            const SizedBox(height: 20),
            _RateRow(
              label: 'Budget Terpakai',
              percent: budgetUsedPercent,
              icon: Icons.pie_chart_outline,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Financial Health',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FinancialHealthScreen()),
                  ),
                  child: const Text('Detail →'),
                ),
              ],
            ),
            _HealthPreviewRow(
              label: 'Tabungan',
              percent: health.savingRate,
              status: health.savingStatus,
            ),
            const SizedBox(height: 8),
            _HealthPreviewRow(
              label: 'Investasi',
              percent: health.investmentRate,
              status: health.investmentStatus,
            ),
            const SizedBox(height: 8),
            _HealthPreviewRow(
              label: 'Pengeluaran',
              percent: health.expenseRate,
              status: health.expenseStatus,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
                    ),
                    icon: const Icon(Icons.bar_chart_outlined, size: 18),
                    label: const Text('Laporan Bulanan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SixMonthProjectionScreen()),
                    ),
                    icon: const Icon(Icons.timeline_outlined, size: 18),
                    label: const Text('Proyeksi 6 Bulan'),
                  ),
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final MonthlySummary summary;
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _StatCard(
          label: 'Pemasukan',
          amount: summary.totalIncome,
          color: AppColors.success,
          icon: Icons.arrow_downward,
        ),
        _StatCard(
          label: 'Pengeluaran',
          amount: summary.totalExpense,
          color: AppColors.error,
          icon: Icons.arrow_upward,
        ),
        _StatCard(
          label: 'Tabungan',
          amount: summary.totalSaving,
          color: AppColors.primary,
          icon: Icons.savings_outlined,
        ),
        _StatCard(
          label: 'Investasi',
          amount: summary.totalInvestment,
          color: AppColors.primary,
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SisaCard extends StatelessWidget {
  final double sisa;
  const _SisaCard({required this.sisa});

  @override
  Widget build(BuildContext context) {
    final isNegative = sisa < 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNegative ? AppColors.error.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: isNegative ? AppColors.error : AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sisa Bulan Ini', style: TextStyle(color: AppColors.textSecondary)),
                Text(
                  CurrencyFormatter.format(sisa),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isNegative ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyLimitCard extends StatelessWidget {
  final double limit;
  const _DailyLimitCard({required this.limit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.today_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Batas Pengeluaran Hari Ini',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(
                  CurrencyFormatter.format(limit),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthPreviewRow extends StatelessWidget {
  final String label;
  final double percent;
  final HealthStatus status;

  const _HealthPreviewRow({required this.label, required this.percent, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(status.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: Text(
            status.label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Text('${percent.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RateRow extends StatelessWidget {
  final String label;
  final double percent;
  final IconData icon;

  const _RateRow({required this.label, required this.percent, required this.icon});

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100).toDouble();
    final displayPercent = percent.toStringAsFixed(1);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 8,
              backgroundColor: AppColors.background,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text('$displayPercent%',
              textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
