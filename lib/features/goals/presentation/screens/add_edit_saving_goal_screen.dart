import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../data/models/saving_goal_model.dart';
import '../providers/saving_goal_providers.dart';

class AddEditSavingGoalScreen extends ConsumerStatefulWidget {
  final SavingGoalModel? goal;
  const AddEditSavingGoalScreen({super.key, this.goal});

  bool get isEditing => goal != null;

  @override
  ConsumerState<AddEditSavingGoalScreen> createState() => _AddEditSavingGoalScreenState();
}

class _AddEditSavingGoalScreenState extends ConsumerState<AddEditSavingGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetController.text = CurrencyFormatter.formatForInput(widget.goal!.targetAmount);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final targetAmount = CurrencyInputFormatter.parse(_targetController.text);
    final controller = ref.read(savingGoalControllerProvider.notifier);

    final success = widget.isEditing
        ? await controller.updateGoal(SavingGoalModel(
            id: widget.goal!.id,
            userId: widget.goal!.userId,
            name: _nameController.text.trim(),
            targetAmount: targetAmount,
            currentAmount: widget.goal!.currentAmount,
          ))
        : await controller.addGoal(name: _nameController.text.trim(), targetAmount: targetAmount);

    if (success && mounted) {
      showGlassSnackBar(
        context,
        widget.isEditing ? 'Target berhasil diperbarui' : 'Target tabungan berhasil dibuat',
      );
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(savingGoalControllerProvider).error;
      showGlassSnackBar(
        context,
        ErrorMapper.toUserMessage(error),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final controllerState = ref.watch(savingGoalControllerProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Target Tabungan' : 'Target Tabungan Baru',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: 'Nama Target Tabungan',
                        hint: 'Contoh: Dana Darurat, Liburan, Gadget',
                        validator: Validators.displayName,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _targetController,
                        label: 'Target Jumlah',
                        hint: 'Rp0',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: (_) => Validators.amount(_targetController.text),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Simpan Target',
                  icon: Icons.check_rounded,
                  isLoading: controllerState.isLoading,
                  onPressed: _save,
                ).animate().fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
