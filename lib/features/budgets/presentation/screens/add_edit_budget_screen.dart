import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../../shared/widgets/searchable_category_field.dart';
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
      showGlassSnackBar(
        context,
        'Pilih kategori terlebih dahulu.',
        isError: true,
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
      showGlassSnackBar(
        context,
        widget.isEditing ? 'Budget berhasil diperbarui' : 'Budget berhasil dibuat',
      );
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(budgetControllerProvider).error;
      showGlassSnackBar(
        context,
        ErrorMapper.toUserMessage(error),
        isError: true,
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Hapus Budget',
      message: 'Budget ini akan dihapus secara permanen.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (confirmed != true) return;
    final success =
        await ref.read(budgetControllerProvider.notifier).deleteBudget(widget.budget!.id);
    if (success && mounted) {
      showGlassSnackBar(context, 'Budget telah dihapus');
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(budgetControllerProvider).error;
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
    final controllerState = ref.watch(budgetControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider(null));
    final income = ref.watch(monthlyIncomeProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Budget' : 'Tambah Budget',
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
                      categoriesAsync.when(
                        data: (categories) {
                          final eligibleCategories = categories
                              .where((c) =>
                                  c.type != TransactionType.income ||
                                  c.id == _categoryId)
                              .toList();
                          return SearchableCategoryField(
                            label: 'Kategori Budget',
                            helperText: 'Pilih pos pengeluaran, tabungan, atau investasi',
                            categories: eligibleCategories,
                            selectedCategoryId: _categoryId,
                            onSelected: (val) => setState(() => _categoryId = val),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Gagal memuat kategori: $e'),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Tipe Budget',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Nominal Tetap'),
                            icon: Icon(Icons.attach_money_rounded),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Persentase (%)'),
                            icon: Icon(Icons.percent_rounded),
                          ),
                        ],
                        selected: {_isPercentage},
                        onSelectionChanged: (Set<bool> selected) {
                          setState(() => _isPercentage = selected.first);
                        },
                      ),
                      const SizedBox(height: 18),
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
                          AnimatedBuilder(
                            animation: _percentController,
                            builder: (context, _) {
                              final pct = double.tryParse(
                                      _percentController.text.trim().replaceAll(',', '.')) ??
                                  0;
                              final estimated = income * pct / 100;
                              return Text(
                                '≈ ${CurrencyFormatter.format(estimated)} dari pendapatan bulan ini (${CurrencyFormatter.format(income)})',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              );
                            },
                          ),
                      ] else
                        AppTextField(
                          controller: _amountController,
                          label: 'Jumlah Nominal',
                          hint: 'Rp0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          validator: (_) => Validators.amount(_amountController.text),
                        ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Aktifkan Budget',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        subtitle: Text(
                          'Budget nonaktif tidak dihitung dalam batas pengeluaran.',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontSize: 12,
                          ),
                        ),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Simpan Budget',
                  icon: Icons.check_rounded,
                  isLoading: controllerState.isLoading,
                  onPressed: _save,
                ).animate().fadeIn(duration: 400.ms),
                if (widget.isEditing) ...[
                  const SizedBox(height: 12),
                  GlassButton(
                    label: 'Hapus Budget',
                    icon: Icons.delete_outline_rounded,
                    backgroundColor: AppColors.expense(context),
                    onPressed: _delete,
                  ).animate().fadeIn(duration: 450.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
