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
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/models/investment_model.dart';
import '../providers/investment_providers.dart';

class AddEditInvestmentScreen extends ConsumerStatefulWidget {
  final InvestmentModel? investment;

  const AddEditInvestmentScreen({super.key, this.investment});

  bool get isEditing => investment != null;

  @override
  ConsumerState<AddEditInvestmentScreen> createState() =>
      _AddEditInvestmentScreenState();
}

class _AddEditInvestmentScreenState
    extends ConsumerState<AddEditInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capitalController = TextEditingController();
  final _currentValueController = TextEditingController();
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final inv = widget.investment;
    _categoryId = inv?.categoryId;
    if (inv != null) {
      _nameController.text = inv.name;
      _capitalController.text = CurrencyFormatter.formatForInput(inv.capital);
      _currentValueController.text =
          CurrencyFormatter.formatForInput(inv.currentValue);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capitalController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      showGlassSnackBar(
        context,
        'Pilih jenis investasi terlebih dahulu.',
        isError: true,
      );
      return;
    }
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;

    final capital = CurrencyInputFormatter.parse(_capitalController.text);
    final currentValue =
        CurrencyInputFormatter.parse(_currentValueController.text);
    final controller = ref.read(investmentControllerProvider.notifier);

    final success = widget.isEditing
        ? await controller.updateInvestment(InvestmentModel(
            id: widget.investment!.id,
            userId: userId,
            categoryId: _categoryId!,
            name: _nameController.text.trim(),
            capital: capital,
            currentValue: currentValue,
            date: widget.investment!.date,
            note: widget.investment!.note,
          ))
        : await controller.addInvestment(
            categoryId: _categoryId!,
            name: _nameController.text.trim(),
            capital: capital,
            currentValue: currentValue,
            date: DateTime.now(),
            note: '',
          );

    if (success && mounted) {
      showGlassSnackBar(
        context,
        widget.isEditing ? 'Investasi berhasil diperbarui' : 'Investasi berhasil ditambahkan',
      );
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(investmentControllerProvider).error;
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
      title: 'Hapus Investasi',
      message: 'Investasi ini akan dihapus secara permanen dari portofolio.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (confirmed != true) return;
    final success = await ref
        .read(investmentControllerProvider.notifier)
        .deleteInvestment(widget.investment!.id);
    if (success && mounted) {
      showGlassSnackBar(context, 'Investasi telah dihapus');
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(investmentControllerProvider).error;
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
    final controllerState = ref.watch(investmentControllerProvider);
    final categoriesAsync =
        ref.watch(categoriesProvider(TransactionType.investment));
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Investasi' : 'Tambah Investasi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: expenseColor),
              tooltip: 'Hapus Investasi',
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
                      categoriesAsync.when(
                        data: (categories) => DropdownButtonFormField<String>(
                          key: ValueKey('inv_cat_$_categoryId'),
                          initialValue:
                              categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                          decoration: const InputDecoration(labelText: 'Jenis Investasi'),
                          items: categories
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (value) => setState(() => _categoryId = value),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Gagal memuat jenis investasi: $e'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _nameController,
                        label: 'Nama Aset / Investasi',
                        hint: 'Contoh: Reksa Dana Pasar Uang, BBCA, Emas Antam',
                        validator: Validators.displayName,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _capitalController,
                        label: 'Modal Awal',
                        hint: 'Rp0',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: (_) => Validators.amount(_capitalController.text),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _currentValueController,
                        label: 'Nilai Sekarang',
                        hint: 'Rp0',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: (_) =>
                            Validators.nonNegativeAmount(_currentValueController.text),
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_capitalController, _currentValueController]),
                        builder: (context, _) {
                          final capital =
                              CurrencyInputFormatter.parse(_capitalController.text);
                          final current = CurrencyInputFormatter.parse(
                              _currentValueController.text);
                          if (capital <= 0) return const SizedBox.shrink();
                          final profit = current - capital;
                          final pct = (profit / capital) * 100;
                          final isProfit = profit >= 0;
                          final badgeColor = isProfit ? incomeColor : expenseColor;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  size: 18,
                                  color: badgeColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${isProfit ? 'Profit' : 'Rugi'}: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                Text(
                                  '${isProfit ? '+' : ''}${CurrencyFormatter.format(profit)} (${isProfit ? '+' : ''}${pct.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: badgeColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Simpan Investasi',
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
