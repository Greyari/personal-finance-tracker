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
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../providers/recurring_providers.dart';

class AddEditRecurringScreen extends ConsumerStatefulWidget {
  final RecurringTransactionModel? recurring;

  const AddEditRecurringScreen({super.key, this.recurring});

  bool get isEditing => recurring != null;

  @override
  ConsumerState<AddEditRecurringScreen> createState() =>
      _AddEditRecurringScreenState();
}

class _AddEditRecurringScreenState
    extends ConsumerState<AddEditRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _percentController = TextEditingController();
  late TransactionType _type;
  String? _categoryId;
  bool _isPercentage = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final r = widget.recurring;
    _type = r?.type ?? TransactionType.expense;
    _categoryId = r?.categoryId;
    _isPercentage = r?.isPercentage ?? false;
    _isActive = r?.isActive ?? true;
    if (r != null) {
      _nameController.text = r.name;
      if (r.isPercentage) {
        _percentController.text = r.value.toStringAsFixed(0);
      } else {
        _amountController.text = CurrencyFormatter.formatForInput(r.value);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;

    final value = _isPercentage
        ? double.parse(_percentController.text.trim().replaceAll(',', '.'))
        : CurrencyInputFormatter.parse(_amountController.text);

    final controller = ref.read(recurringControllerProvider.notifier);
    final success = widget.isEditing
        ? await controller.updateRecurring(RecurringTransactionModel(
            id: widget.recurring!.id,
            userId: userId,
            name: _nameController.text.trim(),
            type: _type,
            categoryId: _categoryId!,
            isPercentage: _isPercentage,
            value: value,
            isActive: _isActive,
            lastGeneratedPeriod: widget.recurring!.lastGeneratedPeriod,
          ))
        : await controller.addRecurring(RecurringTransactionModel(
            id: '',
            userId: userId,
            name: _nameController.text.trim(),
            type: _type,
            categoryId: _categoryId!,
            isPercentage: _isPercentage,
            value: value,
            isActive: _isActive,
          ));

    if (success && mounted) {
      showGlassSnackBar(
        context,
        widget.isEditing
            ? 'Transaksi berulang berhasil diperbarui'
            : 'Transaksi berulang berhasil dibuat',
      );
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(recurringControllerProvider).error;
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
      title: 'Hapus Transaksi Berulang',
      message: 'Konfigurasi transaksi berulang ini akan dihapus permanen.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (confirmed != true) return;
    final success = await ref
        .read(recurringControllerProvider.notifier)
        .deleteRecurring(widget.recurring!.id);
    if (success && mounted) {
      showGlassSnackBar(context, 'Transaksi berulang telah dihapus');
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(recurringControllerProvider).error;
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
    final controllerState = ref.watch(recurringControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider(_type));
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Transaksi Berulang' : 'Tambah Transaksi Berulang',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.expense(context)),
              tooltip: 'Hapus',
              onPressed: _delete,
            ),
        ],
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
                        label: 'Nama Transaksi',
                        hint: 'Contoh: Tagihan Internet, Perpuluhan 10%',
                        validator: Validators.displayName,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Tipe Transaksi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: TransactionType.values.map((type) {
                          final isSelected = type == _type;
                          return InkWell(
                            onTap: () => setState(() {
                              _type = type;
                              _categoryId = null;
                            }),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              child: Text(
                                type.label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? primaryColor : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
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
                      const SizedBox(height: 18),
                      Text(
                        'Metode Perhitungan',
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
                      if (_isPercentage)
                        AppTextField(
                          controller: _percentController,
                          label: 'Persentase (%)',
                          hint: 'Contoh: 10',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: Validators.percentage,
                        )
                      else
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
                          'Aktifkan Transaksi Berulang',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        subtitle: Text(
                          'Transaksi berulang aktif akan otomatis dicatat setiap awal bulan.',
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
                  label: 'Simpan Transaksi Berulang',
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
