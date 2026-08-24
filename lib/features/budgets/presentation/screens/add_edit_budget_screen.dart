import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/models/budget_model.dart';
import '../providers/budget_providers.dart';

class AddEditBudgetScreen extends ConsumerStatefulWidget {
  final BudgetModel? budget;

  const AddEditBudgetScreen({super.key, this.budget});

  bool get isEditing => budget != null;

  @override
  ConsumerState<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends ConsumerState<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _percentController = TextEditingController();
  bool _isPercentage = false;
  String? _categoryId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _isPercentage = b?.isPercentage ?? false;
    _categoryId = b?.categoryId;
    _isActive = b?.isActive ?? true;
    if (b != null) {
      if (b.isPercentage) {
        _percentController.text = b.value.toStringAsFixed(0);
      } else {
        _amountController.text = CurrencyFormatter.formatForInput(b.value);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
      );
      return;
    }

    final value = _isPercentage
        ? double.parse(_percentController.text.trim().replaceAll(',', '.'))
        : CurrencyInputFormatter.parse(_amountController.text);

    final controller = ref.read(budgetControllerProvider.notifier);
    final success = widget.isEditing
        ? await controller.updateBudget(
            BudgetModel(
              id: widget.budget!.id,
              userId: widget.budget!.userId,
              categoryId: _categoryId!,
              isPercentage: _isPercentage,
              value: value,
              isActive: _isActive,
            ),
          )
        : await controller.addBudget(
            categoryId: _categoryId!,
            isPercentage: _isPercentage,
            value: value,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(budgetControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Budget'),
        content: const Text('Budget ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success =
        await ref.read(budgetControllerProvider.notifier).deleteBudget(widget.budget!.id);
    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(budgetControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(budgetControllerProvider);
    // Every category type is eligible for a budget (Gereja/expense,
    // Tabungan/saving, Investasi/investment are all valid examples from
    // the spec), so this intentionally passes null rather than filtering
    // by TransactionType.expense.
    final categoriesAsync = ref.watch(categoriesProvider(null));
    final income = ref.watch(monthlyIncomeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Budget' : 'Tambah Budget'),
        actions: [
          if (widget.isEditing)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    value: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.name} (${c.type.label})'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Gagal memuat kategori: $e'),
                ),
                const SizedBox(height: 16),
                const Text('Tipe Budget', style: TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Nominal'),
                        value: false,
                        groupValue: _isPercentage,
                        onChanged: (value) => setState(() => _isPercentage = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Persentase'),
                        value: true,
                        groupValue: _isPercentage,
                        onChanged: (value) => setState(() => _isPercentage = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isPercentage) ...[
                  AppTextField(
                    controller: _percentController,
                    label: 'Persentase (%)',
                    hint: 'Contoh: 10',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.percentage,
                  ),
                  const SizedBox(height: 8),
                  if (income > 0)
                    // AnimatedBuilder listens to the controller directly so
                    // this preview updates on every keystroke without
                    // needing setState calls scattered through onChanged.
                    AnimatedBuilder(
                      animation: _percentController,
                      builder: (context, _) {
                        final pct = double.tryParse(
                                _percentController.text.trim().replaceAll(',', '.')) ??
                            0;
                        final estimated = income * pct / 100;
                        return Text(
                          '≈ ${CurrencyFormatter.format(estimated)} dari pendapatan bulan ini (${CurrencyFormatter.format(income)})',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        );
                      },
                    ),
                ] else
                  AppTextField(
                    controller: _amountController,
                    label: 'Jumlah',
                    hint: 'Rp0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    validator: (_) => Validators.amount(_amountController.text),
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  subtitle: const Text(
                      'Budget nonaktif tidak dihitung dalam total maupun progress.'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 16),
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
