import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../../shared/widgets/searchable_category_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../goals/data/models/saving_goal_model.dart';
import '../../../goals/presentation/providers/saving_goal_providers.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_providers.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;
  final TransactionType? initialType;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
    this.initialType,
  });

  bool get isEditing => transaction != null;

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late TransactionType _type;
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx?.type ?? widget.initialType ?? TransactionType.expense;
    _categoryId = tx?.categoryId;
    _selectedGoalId = tx?.goalId;
    _date = tx?.date ?? DateTime.now();
    if (tx != null) {
      _amountController.text = CurrencyFormatter.formatForInput(tx.amount);
      _descriptionController.text = tx.description;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type != TransactionType.saving && _categoryId == null) {
      showGlassSnackBar(
        context,
        'Pilih kategori terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (_type == TransactionType.saving && _selectedGoalId == null) {
      showGlassSnackBar(
        context,
        'Pilih target tabungan (Goal) terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;

    final amount = CurrencyInputFormatter.parse(_amountController.text);
    final controller = ref.read(transactionControllerProvider.notifier);
    final savingRepo = ref.read(savingGoalRepositoryProvider);
    final categoryIdToSave = _type == TransactionType.saving
        ? (_selectedGoalId ?? 'saving')
        : _categoryId!;
    final note = _descriptionController.text.trim().isNotEmpty
        ? _descriptionController.text.trim()
        : 'Tabungan dari transaksi';

    if (widget.isEditing) {
      final oldTx = widget.transaction!;
      final oldGoalId = oldTx.goalId;
      final oldAmount = oldTx.amount;
      final wasSaving = oldTx.type == TransactionType.saving && oldGoalId != null;
      final isSaving = _type == TransactionType.saving && _selectedGoalId != null;

      final success = await controller.updateTransaction(
        TransactionModel(
          id: oldTx.id,
          userId: userId,
          type: _type,
          categoryId: categoryIdToSave,
          amount: amount,
          description: _descriptionController.text.trim(),
          date: _date,
          recurringId: oldTx.recurringId,
          generatedPeriod: oldTx.generatedPeriod,
          goalId: _selectedGoalId,
        ),
      );

      if (success) {
        try {
          if (wasSaving && isSaving) {
            await savingRepo.updateContributionFromTransaction(
              userId: userId,
              transactionId: oldTx.id,
              newGoalId: _selectedGoalId!,
              newAmount: amount,
              newNote: note,
              newDate: _date,
              oldGoalId: oldGoalId,
              oldAmount: oldAmount,
            );
          } else if (wasSaving && !isSaving) {
            await savingRepo.deleteContributionFromTransaction(
              userId: userId,
              goalId: oldGoalId,
              transactionId: oldTx.id,
              amount: oldAmount,
            );
          } else if (!wasSaving && isSaving) {
            await savingRepo.addContributionFromTransaction(
              userId: userId,
              goalId: _selectedGoalId!,
              transactionId: oldTx.id,
              amount: amount,
              note: note,
              date: _date,
            );
          }
        } catch (_) {}

        if (!mounted) return;
        showGlassSnackBar(context, 'Transaksi berhasil diperbarui');
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        final error = ref.read(transactionControllerProvider).error;
        showGlassSnackBar(
          context,
          ErrorMapper.toUserMessage(error),
          isError: true,
        );
      }
    } else {
      // Adding new transaction
      final newTxId = await controller.addTransaction(
        TransactionModel(
          id: '',
          userId: userId,
          type: _type,
          categoryId: categoryIdToSave,
          amount: amount,
          description: _descriptionController.text.trim(),
          date: _date,
          goalId: _selectedGoalId,
        ),
      );

      if (newTxId != null) {
        if (_type == TransactionType.saving && _selectedGoalId != null) {
          try {
            await savingRepo.addContributionFromTransaction(
              userId: userId,
              goalId: _selectedGoalId!,
              transactionId: newTxId,
              amount: amount,
              note: note,
              date: _date,
            );
          } catch (_) {}
        }

        if (!mounted) return;
        showGlassSnackBar(
          context,
          _selectedGoalId != null
              ? 'Transaksi dicatat & masuk ke target tabungan 🎉'
              : 'Transaksi berhasil dicatat',
        );
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        final error = ref.read(transactionControllerProvider).error;
        showGlassSnackBar(
          context,
          ErrorMapper.toUserMessage(error),
          isError: true,
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Hapus Transaksi',
      message: 'Transaksi ini akan dihapus secara permanen dari catatan keuanganmu.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (confirmed != true) return;

    final userId = ref.read(authStateProvider).value?.uid;
    if (userId != null && widget.transaction != null) {
      if (widget.transaction!.type == TransactionType.saving && widget.transaction!.goalId != null) {
        try {
          await ref.read(savingGoalRepositoryProvider).deleteContributionFromTransaction(
            userId: userId,
            goalId: widget.transaction!.goalId!,
            transactionId: widget.transaction!.id,
            amount: widget.transaction!.amount,
          );
        } catch (_) {}
      }
    }

    final success = await ref
        .read(transactionControllerProvider.notifier)
        .deleteTransaction(widget.transaction!.id);
    if (!mounted) return;
    if (success) {
      showGlassSnackBar(context, 'Transaksi telah dihapus');
      Navigator.of(context).pop();
    } else {
      final error = ref.read(transactionControllerProvider).error;
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
    final controllerState = ref.watch(transactionControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider(_type));
    final savingGoalsAsync = ref.watch(savingGoalsProvider);

    final String screenTitle;
    if (widget.isEditing) {
      screenTitle = 'Edit Transaksi';
    } else if (_type.isIncome) {
      screenTitle = 'Catat Uang Masuk';
    } else if (_type.isExpense) {
      screenTitle = 'Catat Uang Keluar';
    } else if (_type.isSaving) {
      screenTitle = 'Alokasi Tabungan (Goal)';
    } else {
      screenTitle = 'Tambah Transaksi';
    }

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          screenTitle,
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
                _TypeSelector(
                  selected: _type,
                  onChanged: (type) => setState(() {
                    _type = type;
                    _categoryId = null;
                  }),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 18),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _amountController,
                        label: 'Nominal (${_type.subtitle})',
                        hint: 'Rp0',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: (_) => Validators.amount(_amountController.text),
                      ),
                      if (_type != TransactionType.saving) ...[
                        const SizedBox(height: 16),
                        categoriesAsync.when(
                          data: (categories) => SearchableCategoryField(
                            label: 'Kategori',
                            categories: categories,
                            selectedCategoryId: _categoryId,
                            onSelected: (value) => setState(() => _categoryId = value),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Gagal memuat kategori: $e'),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        _GoalSelectorSection(
                          goalsAsync: savingGoalsAsync,
                          selectedGoalId: _selectedGoalId,
                          isRequired: true,
                          onChanged: (goalId) => setState(() => _selectedGoalId = goalId),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _descriptionController,
                        label: 'Catatan / Keterangan (opsional)',
                        hint: _type.isIncome
                            ? 'Contoh: Gaji bulanan, penjualan'
                            : _type.isExpense
                                ? 'Contoh: Makan siang, belanja bulanan'
                                : 'Contoh: Setoran tabungan bulanan',
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(18),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal Transaksi',
                            suffixIcon: Icon(
                              Icons.calendar_today_rounded,
                              size: 19,
                              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                            ),
                          ),
                          child: Text(DateFormat.yMMMMd('id_ID').format(_date)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Simpan Transaksi',
                  icon: Icons.check_rounded,
                  isLoading: controllerState.isLoading,
                  onPressed: _save,
                ).animate().fadeIn(duration: 400.ms),
                if (widget.isEditing) ...[
                  const SizedBox(height: 12),
                  GlassButton(
                    label: 'Hapus Transaksi',
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

class _GoalSelectorSection extends StatelessWidget {
  final AsyncValue<List<SavingGoalModel>> goalsAsync;
  final String? selectedGoalId;
  final bool isRequired;
  final ValueChanged<String?> onChanged;

  const _GoalSelectorSection({
    required this.goalsAsync,
    required this.selectedGoalId,
    this.isRequired = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                isRequired ? 'Target Tabungan (Goal) *' : 'Hubungkan ke Target Tabungan',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Nominal ini akan langsung dialokasikan ke target tabungan dan otomatis tercatat pada riwayat kontribusinya.',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          goalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x33000000) : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Belum ada target tabungan dibuat di tab Goals.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final validSelectedId =
                  goals.any((g) => g.id == selectedGoalId) ? selectedGoalId : null;

              return DropdownButtonFormField<String?>(
                key: ValueKey('goal_select_${validSelectedId ?? 'none'}'),
                initialValue: validSelectedId,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                decoration: InputDecoration(
                  labelText: isRequired ? 'Pilih Target Tabungan *' : 'Pilih Target Tabungan',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: [
                  if (!isRequired)
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tidak dihubungkan ke target'),
                    ),
                  ...goals.map((g) {
                    final percent = (g.progress * 100).toStringAsFixed(0);
                    return DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text('${g.name} ($percent%)'),
                    );
                  }),
                ],
                onChanged: onChanged,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Gagal memuat target tabungan: $e'),
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);
    final isDark = AppColors.isDark(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TransactionType.values.map((type) {
        final isSelected = type == selected;
        Color activeColor;
        switch (type) {
          case TransactionType.income:
            activeColor = incomeColor;
            break;
          case TransactionType.expense:
            activeColor = expenseColor;
            break;
          case TransactionType.saving:
          case TransactionType.investment:
            activeColor = primaryColor;
            break;
        }

        return InkWell(
          onTap: () => onChanged(type),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: isDark ? 0.22 : 0.15)
                  : (isDark ? AppColors.glassFillDark : AppColors.glassFillLight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type.isIncome)
                  Icon(Icons.arrow_downward_rounded, size: 15, color: isSelected ? activeColor : null),
                if (type.isExpense)
                  Icon(Icons.arrow_upward_rounded, size: 15, color: isSelected ? activeColor : null),
                if (type.isSaving)
                  Icon(Icons.flag_rounded, size: 15, color: isSelected ? activeColor : null),
                if (type.isIncome || type.isExpense || type.isSaving) const SizedBox(width: 5),
                Text(
                  type.isIncome
                      ? 'Uang Masuk'
                      : type.isExpense
                          ? 'Uang Keluar'
                          : type.label,
                  style: TextStyle(
                    color: isSelected ? activeColor : null,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
