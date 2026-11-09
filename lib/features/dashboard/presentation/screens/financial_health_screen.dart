import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../providers/financial_health_provider.dart';

class FinancialHealthScreen extends ConsumerWidget {
  const FinancialHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final health = ref.watch(financialHealthProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          'Financial Health',
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

          _HealthCard(
            label: 'Rasio Tabungan (Saving Rate)',
            description: 'Persentase uang masuk yang berhasil disisihkan ke tabungan.',
            percent: health.savingRate,
            status: health.savingStatus,
            icon: Icons.savings_rounded,
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 12),

          _HealthCard(
            label: 'Rasio Investasi (Investment Rate)',
            description: 'Persentase uang masuk yang dialokasikan ke instrumen investasi.',
            percent: health.investmentRate,
            status: health.investmentStatus,
            icon: Icons.trending_up_rounded,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 12),

          _HealthCard(
            label: 'Rasio Pengeluaran (Expense Rate)',
            description: 'Persentase uang keluar dibandingkan total pemasukan.',
            percent: health.expenseRate,
            status: health.expenseStatus,
            icon: Icons.receipt_long_rounded,
          ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Analisis ini adalah gambaran rasio berdasarkan catatan transaksi Anda, '
                    'bukan nasihat investasi formal. Aplikasi berfungsi sebagai asisten '
                    'pencatatan dan analisis agar keuangan Anda tetap seimbang dan sehat.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String label;
  final String description;
  final double percent;
  final HealthStatus status;
  final IconData icon;

  const _HealthCard({
    required this.label,
    required this.description,
    required this.percent,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final clamped = percent.clamp(0, 100).toDouble();
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(status.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.4,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0x33FFFFFF) : const Color(0x1F0F172A),
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
