import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../providers/report_providers.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  TransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final summary = ref.watch(monthlySummaryProvider);
    final allBreakdown = ref.watch(categoryBreakdownProvider);

    final breakdown = _filterType == null
        ? allBreakdown
        : allBreakdown.where((e) => e.type == _filterType).toList();

    final maxTotal = breakdown.isEmpty
        ? 1.0
        : breakdown.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    final hasData = summary.totalIncome > 0 || summary.totalExpense > 0;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          'Laporan Bulanan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
        children: [
          const MonthSelector().animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 14),

          // Total Summary Card
          _TotalsCard(summary: summary)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),

          // Visual Chart (Cashflow Pie Chart)
          if (hasData)
            _CashFlowChartCard(summary: summary)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 18),

          // Breakdown Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rincian per Kategori',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.glassFillDark : AppColors.glassFillLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
                  ),
                ),
                child: DropdownButton<TransactionType?>(
                  value: _filterType,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua Pos')),
                    DropdownMenuItem(value: TransactionType.expense, child: Text('Pengeluaran')),
                    DropdownMenuItem(value: TransactionType.income, child: Text('Pemasukan')),
                    DropdownMenuItem(value: TransactionType.saving, child: Text('Tabungan')),
                    DropdownMenuItem(value: TransactionType.investment, child: Text('Investasi')),
                  ],
                  onChanged: (val) => setState(() => _filterType = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (breakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Belum ada transaksi di pos ini untuk bulan terpilih.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
          else
            ...breakdown.asMap().entries.map((entry) {
              final index = entry.key;
              final b = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BreakdownTile(entry: b, maxTotal: maxTotal),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 25 * index.clamp(0, 10)),
                    duration: 200.ms,
                  );
            }),
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
    final isDark = AppColors.isDark(context);
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        children: [
          _TotalRow(
            label: 'Total Pemasukan (Masuk)',
            amount: summary.totalIncome,
            color: incomeColor,
            icon: Icons.arrow_downward_rounded,
          ),
          Divider(
            height: 22,
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x10000000),
          ),
          _TotalRow(
            label: 'Total Pengeluaran (Keluar)',
            amount: summary.totalExpense,
            color: expenseColor,
            icon: Icons.arrow_upward_rounded,
          ),
          Divider(
            height: 22,
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x10000000),
          ),
          _TotalRow(
            label: 'Selisih Kas Bersih (Net)',
            amount: summary.netCashFlow,
            color: summary.netCashFlow >= 0
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                : expenseColor,
            showPlusIfPositive: true,
            icon: Icons.swap_horiz_rounded,
            isBold: true,
          ),
          Divider(
            height: 22,
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x10000000),
          ),
          _TotalRow(
            label: 'Total Tabungan Disisihkan',
            amount: summary.totalSaving,
            color: secondaryColor,
            icon: Icons.savings_rounded,
          ),
          Divider(
            height: 22,
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x10000000),
          ),
          _TotalRow(
            label: 'Total Investasi Disalurkan',
            amount: summary.totalInvestment,
            color: primaryColor,
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool showPlusIfPositive;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.showPlusIfPositive = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final prefix = (showPlusIfPositive && amount > 0) ? '+' : '';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Text(
          '$prefix${CurrencyFormatter.format(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isBold ? 15 : 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CashFlowChartCard extends StatelessWidget {
  final MonthlySummary summary;
  const _CashFlowChartCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);
    final total = summary.totalIncome + summary.totalExpense;

    if (total <= 0) return const SizedBox.shrink();

    final incomePct = ((summary.totalIncome / total) * 100).round();
    final expensePct = 100 - incomePct;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rasio Arus Kas Masuk vs Keluar',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 28,
                    sections: [
                      if (summary.totalIncome > 0)
                        PieChartSectionData(
                          value: summary.totalIncome,
                          color: incomeColor,
                          radius: 24,
                          showTitle: false,
                        ),
                      if (summary.totalExpense > 0)
                        PieChartSectionData(
                          value: summary.totalExpense,
                          color: expenseColor,
                          radius: 24,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChartLegend(
                      color: incomeColor,
                      label: 'Pemasukan',
                      percent: '$incomePct%',
                      amount: CurrencyFormatter.format(summary.totalIncome),
                    ),
                    const SizedBox(height: 10),
                    _ChartLegend(
                      color: expenseColor,
                      label: 'Pengeluaran',
                      percent: '$expensePct%',
                      amount: CurrencyFormatter.format(summary.totalExpense),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String percent;
  final String amount;

  const _ChartLegend({
    required this.color,
    required this.label,
    required this.percent,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    percent,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  final CategoryBreakdownEntry entry;
  final double maxTotal;
  const _BreakdownTile({required this.entry, required this.maxTotal});

  Color _typeColor(BuildContext context) {
    final isDark = AppColors.isDark(context);
    switch (entry.type) {
      case TransactionType.income:
        return AppColors.income(context);
      case TransactionType.expense:
        return AppColors.expense(context);
      case TransactionType.saving:
      case TransactionType.investment:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final fraction = maxTotal <= 0 ? 0.0 : (entry.total / maxTotal).clamp(0.0, 1.0);
    final color = _typeColor(context);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CategoryIcons.resolve(entry.categoryIcon),
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.categoryName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      entry.type.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(entry.total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0x33FFFFFF) : const Color(0x1F0F172A),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
