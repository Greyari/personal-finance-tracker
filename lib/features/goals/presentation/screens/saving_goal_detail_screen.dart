import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../data/models/saving_goal_model.dart';
import '../providers/saving_goal_providers.dart';
import 'add_edit_saving_goal_screen.dart';

class SavingGoalDetailScreen extends ConsumerWidget {
  final SavingGoalModel goal;
  const SavingGoalDetailScreen({super.key, required this.goal});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Hapus Target Tabungan',
      message: 'Target tabungan ini beserta seluruh riwayat kontribusinya akan dihapus permanen.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      final success = await ref.read(savingGoalControllerProvider.notifier).deleteGoal(goal.id);
      if (success && context.mounted) {
        showGlassSnackBar(context, 'Target tabungan telah dihapus');
        Navigator.of(context).pop();
      } else if (!success && context.mounted) {
        final error = ref.read(savingGoalControllerProvider).error;
        showGlassSnackBar(
          context,
          ErrorMapper.toUserMessage(error),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final goalsAsync = ref.watch(savingGoalsProvider);
    final contributionsAsync = ref.watch(goalContributionsProvider(goal.id));

    final matches = goalsAsync.value?.where((g) => g.id == goal.id) ?? const [];
    final currentGoal = matches.isNotEmpty ? matches.first : goal;
    final incomeColor = AppColors.income(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final accentColor = currentGoal.isAchieved ? incomeColor : primaryColor;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          currentGoal.name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Target',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddEditSavingGoalScreen(goal: currentGoal)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.expense(context)),
            tooltip: 'Hapus Target',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: GlassCard(
              padding: const EdgeInsets.all(22),
              borderRadius: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Terkumpul',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          currentGoal.isAchieved
                              ? 'Tercapai 🎉'
                              : '${(currentGoal.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
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
                      CurrencyFormatter.format(currentGoal.currentAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: -0.6,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'dari target ${CurrencyFormatter.format(currentGoal.targetAmount)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: currentGoal.progress,
                      minHeight: 8,
                      backgroundColor: isDark ? const Color(0x33FFFFFF) : const Color(0x1F0F172A),
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Riwayat Kontribusi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              onRefresh: () async {
                ref.invalidate(savingGoalsProvider);
                ref.invalidate(goalContributionsProvider(goal.id));
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: contributionsAsync.when(
                data: (contributions) {
                  if (contributions.isEmpty) {
                    return LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.savings_outlined,
                                    size: 48,
                                    color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada tabungan masuk untuk target ini.\nCatat transaksi dengan jenis Tabungan dan pilih target ini.',
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
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: contributions.length,
                    itemBuilder: (context, index) {
                      final c = contributions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          borderRadius: 16,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: incomeColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_downward_rounded, size: 16, color: incomeColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '+${CurrencyFormatter.format(c.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: incomeColor,
                                      ),
                                    ),
                                    Text(
                                      c.note.isEmpty
                                          ? DateFormat.yMMMd('id_ID').format(c.date)
                                          : '${c.note} · ${DateFormat.yMMMd('id_ID').format(c.date)}',
                                      style: TextStyle(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        fontSize: 11.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: 25 * index.clamp(0, 10)),
                            duration: 200.ms,
                          );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(child: Text('Terjadi kesalahan: $e')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
