import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/projection_provider.dart';

class SixMonthProjectionScreen extends ConsumerWidget {
  const SixMonthProjectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projection = ref.watch(sixMonthProjectionProvider);
    final hasIncome = projection.months.isNotEmpty && projection.months.first.income > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Proyeksi 6 Bulan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!hasIncome)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Belum ada pemasukan tercatat bulan ini — proyeksi di bawah dihitung '
                'dari budget tabungan/investasi aktif Anda saja.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ...projection.months.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MonthCard(month: m),
              )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Target 6 Bulan',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                _TargetRow(label: 'Target tabungan', amount: projection.totalSavingTarget),
                const SizedBox(height: 6),
                _TargetRow(label: 'Target investasi', amount: projection.totalInvestmentTarget),
                const Divider(height: 20),
                _TargetRow(
                  label: 'Total target aset',
                  amount: projection.totalAssetTarget,
                  emphasize: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final MonthProjection month;
  const _MonthCard({required this.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.background,
            child: Text('${month.monthIndex}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bulan ${month.monthIndex}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Income ${CurrencyFormatter.format(month.income)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Saving ${CurrencyFormatter.format(month.saving)}',
                  style: const TextStyle(fontSize: 12)),
              Text('Invest ${CurrencyFormatter.format(month.investment)}',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool emphasize;
  const _TargetRow({required this.label, required this.amount, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: emphasize ? FontWeight.w700 : FontWeight.normal)),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: emphasize ? 18 : 14,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
