import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/saving_goal_model.dart';
import '../providers/saving_goal_providers.dart';
import 'add_edit_saving_goal_screen.dart';

class SavingGoalDetailScreen extends ConsumerWidget {
  final SavingGoalModel goal;
  const SavingGoalDetailScreen({super.key, required this.goal});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Target'),
        content: const Text(
            'Target tabungan ini beserta seluruh riwayat kontribusinya akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await ref.read(savingGoalControllerProvider.notifier).deleteGoal(goal.id);
      if (success && context.mounted) {
        Navigator.of(context).pop();
      } else if (!success && context.mounted) {
        final error = ref.read(savingGoalControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
        );
      }
    }
  }

  Future<void> _addContribution(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tambah Kontribusi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              AppTextField(
                controller: amountController,
                label: 'Jumlah',
                hint: 'Rp0',
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                validator: (_) => Validators.amount(amountController.text),
              ),
              const SizedBox(height: 12),
              AppTextField(controller: noteController, label: 'Catatan (opsional)'),
              const SizedBox(height: 16),
              AppButton(
                label: 'Tambahkan',
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(sheetContext).pop(true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final amount = CurrencyInputFormatter.parse(amountController.text);
      final success = await ref.read(savingGoalControllerProvider.notifier).addContribution(
            goalId: goal.id,
            amount: amount,
            note: noteController.text.trim(),
            date: DateTime.now(),
          );
      if (!success && context.mounted) {
        final error = ref.read(savingGoalControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingGoalsProvider);
    final contributionsAsync = ref.watch(goalContributionsProvider(goal.id));

    // Always reads the freshest copy from the live stream so
    // currentAmount reflects contributions added while this screen is
    // open, without needing this widget to manage its own state.
    final matches = goalsAsync.value?.where((g) => g.id == goal.id) ?? const [];
    final currentGoal = matches.isNotEmpty ? matches.first : goal;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentGoal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddEditSavingGoalScreen(goal: currentGoal)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${CurrencyFormatter.format(currentGoal.currentAmount)} / ${CurrencyFormatter.format(currentGoal.targetAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: currentGoal.progress,
                    minHeight: 10,
                    backgroundColor: AppColors.background,
                    color: currentGoal.isAchieved ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(currentGoal.progress * 100).toStringAsFixed(0)}%'
                  '${currentGoal.isAchieved ? ' · Tercapai! 🎉' : ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: contributionsAsync.when(
              data: (contributions) {
                if (contributions.isEmpty) {
                  return const Center(
                    child: Text('Belum ada kontribusi.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount: contributions.length,
                  itemBuilder: (context, index) {
                    final c = contributions[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.background,
                        child: Icon(Icons.add, color: AppColors.success),
                      ),
                      title: Text('+${CurrencyFormatter.format(c.amount)}'),
                      subtitle: Text(
                        c.note.isEmpty
                            ? DateFormat.yMMMd('id_ID').format(c.date)
                            : '${c.note} · ${DateFormat.yMMMd('id_ID').format(c.date)}',
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addContribution(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Kontribusi'),
      ),
    );
  }
}
