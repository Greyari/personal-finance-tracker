import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
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
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(savingGoalControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(savingGoalControllerProvider);
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Target Tabungan' : 'Target Tabungan Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Nama Target',
                  hint: 'Contoh: Dana Darurat',
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
                const SizedBox(height: 24),
                AppButton(
                  label: 'Simpan',
                  isLoading: controllerState.isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
