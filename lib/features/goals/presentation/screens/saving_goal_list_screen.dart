import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/saving_goal_model.dart';
import '../providers/saving_goal_providers.dart';
import 'add_edit_saving_goal_screen.dart';
import 'saving_goal_detail_screen.dart';

class SavingGoalListScreen extends ConsumerWidget {
  const SavingGoalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingGoalsProvider);

    return Scaffold(
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada target tabungan.\nTekan tombol + untuk membuat target pertama Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalCard(goal: goals[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_saving_goal',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditSavingGoalScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingGoalModel goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).toStringAsFixed(0);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SavingGoalDetailScreen(goal: goal)),
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
            Row(
              children: [
                Expanded(
                  child: Text(goal.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                if (goal.isAchieved)
                  const Icon(Icons.emoji_events_outlined, color: AppColors.success),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: AppColors.background,
                color: goal.isAchieved ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text('$percent%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
