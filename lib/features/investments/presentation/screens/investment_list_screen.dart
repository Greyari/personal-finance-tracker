import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../data/models/investment_model.dart';
import '../providers/investment_providers.dart';
import 'add_edit_investment_screen.dart';

class InvestmentListScreen extends ConsumerWidget {
  const InvestmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final investmentsAsync = ref.watch(investmentsProvider);
    final summary = ref.watch(investmentSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: investmentsAsync.when(
        data: (investments) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            _SummaryCard(summary: summary)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 16),
            if (investments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 48,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada portofolio investasi tercatat.\nTekan tombol di bawah untuk menambahkan.',
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
              ).animate().fadeIn(duration: 350.ms)
            else
              ...investments.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final i = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InvestmentTile(investment: i),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
                        duration: 250.ms,
                      );
                },
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
      floatingActionButton: GlassCircularFab(
        heroTag: 'fab_add_investment',
        tooltip: 'Investasi Baru',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditInvestmentScreen()),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final InvestmentSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isProfit = summary.totalProfit >= 0;
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);
    final profitColor = isProfit ? incomeColor : expenseColor;

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
                'Total Nilai Portofolio',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: profitColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: profitColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${isProfit ? '+' : ''}${summary.returnPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: profitColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(summary.totalCurrentValue),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Total Modal',
                  value: CurrencyFormatter.format(summary.totalCapital),
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: isDark ? const Color(0x22FFFFFF) : const Color(0x18000000),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: isProfit ? 'Total Profit' : 'Total Rugi',
                  value: '${isProfit ? '+' : '-'}${CurrencyFormatter.format(summary.totalProfit.abs())}',
                  color: profitColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ),
        ),
      ],
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  final InvestmentModel investment;
  const _InvestmentTile({required this.investment});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isProfit = investment.profit >= 0;
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);
    final profitColor = isProfit ? incomeColor : expenseColor;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddEditInvestmentScreen(investment: investment)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: profitColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: profitColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  investment.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Modal ${CurrencyFormatter.format(investment.capital)} → ${CurrencyFormatter.format(investment.currentValue)}',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isProfit ? '+' : '-'}${CurrencyFormatter.format(investment.profit.abs())}',
                style: TextStyle(
                  color: profitColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                '${isProfit ? '+' : ''}${investment.returnPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: profitColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
