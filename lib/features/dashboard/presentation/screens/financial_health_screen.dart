import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../providers/financial_health_provider.dart';

class FinancialHealthScreen extends ConsumerWidget {
  const FinancialHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(financialHealthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Health')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const MonthSelector(),
          const SizedBox(height: 16),
          _HealthRow(
              label: 'Saving Rate', percent: health.savingRate, status: health.savingStatus),
          const SizedBox(height: 12),
          _HealthRow(
              label: 'Investment Rate',
              percent: health.investmentRate,
              status: health.investmentStatus),
          const SizedBox(height: 12),
          _HealthRow(
              label: 'Expense Rate', percent: health.expenseRate, status: health.expenseStatus),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Angka ini adalah gambaran umum berdasarkan catatan transaksi Anda, '
              'bukan nasihat investasi. Aplikasi ini hanya berfungsi sebagai alat '
              'pencatatan dan analisis — keputusan keuangan tetap sepenuhnya di '
              'tangan Anda.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final double percent;
  final HealthStatus status;

  const _HealthRow({required this.label, required this.percent, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(status.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(status.label,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text('${percent.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}
