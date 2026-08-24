import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/investment_model.dart';
import '../providers/investment_providers.dart';
import 'add_edit_investment_screen.dart';

class InvestmentListScreen extends ConsumerWidget {
  const InvestmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investmentsAsync = ref.watch(investmentsProvider);
    final summary = ref.watch(investmentSummaryProvider);

    return Scaffold(
      body: investmentsAsync.when(
        data: (investments) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(summary: summary),
            const SizedBox(height: 16),
            if (investments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Belum ada investasi tercatat.\nTekan tombol + untuk menambahkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...investments.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InvestmentTile(investment: i),
                  )),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_investment',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditInvestmentScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final InvestmentSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isProfit = summary.totalProfit >= 0;
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
          const Text('Total Portofolio', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(CurrencyFormatter.format(summary.totalCurrentValue),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: 'Modal', value: CurrencyFormatter.format(summary.totalCapital)),
              ),
              Expanded(
                child: _MiniStat(
                  label: isProfit ? 'Profit' : 'Rugi',
                  value: CurrencyFormatter.format(summary.totalProfit.abs()),
                  color: isProfit ? AppColors.success : AppColors.error,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Return',
                  value: '${summary.returnPercent.toStringAsFixed(1)}%',
                  color: isProfit ? AppColors.success : AppColors.error,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  final InvestmentModel investment;
  const _InvestmentTile({required this.investment});

  @override
  Widget build(BuildContext context) {
    final isProfit = investment.profit >= 0;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddEditInvestmentScreen(investment: investment)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(investment.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Modal ${CurrencyFormatter.format(investment.capital)} → ${CurrencyFormatter.format(investment.currentValue)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${isProfit ? '+' : '-'}${CurrencyFormatter.format(investment.profit.abs())} '
              '(${investment.returnPercent.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: isProfit ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
