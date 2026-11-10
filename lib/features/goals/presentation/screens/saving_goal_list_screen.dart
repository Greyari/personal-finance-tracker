import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../data/models/saving_goal_model.dart';
import '../providers/saving_goal_providers.dart';
import 'add_edit_saving_goal_screen.dart';
import 'saving_goal_detail_screen.dart';

class SavingGoalListScreen extends ConsumerWidget {
  const SavingGoalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final goalsAsync = ref.watch(savingGoalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          GlassSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(savingGoalsProvider);
              await Future.delayed(const Duration(milliseconds: 600));
            },
          ),
          ...goalsAsync.when(
            skipLoadingOnRefresh: true,
            data: (goals) {
              if (goals.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 48,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada target tabungan.\nTekan tombol di bawah untuk membuat target pertama.',
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
                ];
              }
              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GoalCard(goal: goals[index]),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
                            duration: 250.ms,
                          ),
                      childCount: goals.length,
                    ),
                  ),
                ),
              ];
            },
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Terjadi kesalahan: $e')),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: GlassCircularFab(
        heroTag: 'fab_add_saving_goal',
        tooltip: 'Target Baru',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditSavingGoalScreen()),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingGoalModel goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final percent = (goal.progress * 100).toStringAsFixed(0);
    final incomeColor = AppColors.income(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final accentColor = goal.isAchieved ? incomeColor : primaryColor;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SavingGoalDetailScreen(goal: goal)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  goal.isAchieved ? Icons.emoji_events_rounded : Icons.savings_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              if (goal.isAchieved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: incomeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Tercapai 🎉',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: incomeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 7,
              backgroundColor: isDark ? const Color(0x33FFFFFF) : const Color(0x1F0F172A),
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
