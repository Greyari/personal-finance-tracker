import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../providers/recurring_providers.dart';

class AddEditRecurringScreen extends ConsumerStatefulWidget {
  final RecurringTransactionModel? recurring;
  const AddEditRecurringScreen({super.key, this.recurring});

  bool get isEditing => recurring != null;

  @override
  ConsumerState<AddEditRecurringScreen> createState() => _AddEditRecurringScreenState();
}

class _AddEditRecurringScreenState extends ConsumerState<AddEditRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _percentController = TextEditingController();
  late TransactionType _type;
  bool _isPercentage = false;
  String? _categoryId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final r = widget.recurring;
    _type = r?.type ?? TransactionType.expense;
    _isPercentage = r?.isPercentage ?? false;
    _categoryId = r?.categoryId;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
      );
      return;
    }
    final value = _isPercentage
        ? double.parse(_percentController.text.trim().replaceAll(',', '.'))
        : CurrencyInputFormatter.parse(_amountController.text);

    final controller = ref.read(recurringControllerProvider.notifier);
    final success = widget.isEditing
        ? await controller.updateRecurring(RecurringTransactionModel(
            id: widget.recurring!.id,
            userId: widget.recurring!.userId,
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
            userId: ref.read(authStateProvider).value!.uid,
            name: _nameController.text.trim(),
            type: _type,
            categoryId: _categoryId!,
            isPercentage: _isPercentage,
            value: value,
            isActive: _isActive,
          ));

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(recurringControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi Berulang'),
        content: const Text(
            'Konfigurasi ini akan dihapus. Transaksi yang sudah pernah dibuat sebelumnya tidak ikut terhapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await ref
        .read(recurringControllerProvider.notifier)
        .deleteRecurring(widget.recurring!.id);
    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(recurringControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(recurringControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider(_type));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Transaksi Berulang' : 'Transaksi Berulang Baru'),
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
                AppTextField(
                  controller: _nameController,
                  label: 'Nama',
                  hint: 'Contoh: Internet, Gereja',
                  validator: Validators.displayName,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: TransactionType.values.map((type) {
                    final isSelected = type == _type;
                    return ChoiceChip(
                      label: Text(type.label),
                      selected: isSelected,
                      onSelected: (_) => setState(() {
                        _type = type;
                        _categoryId = null;
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    value: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Gagal memuat kategori: $e'),
                ),
                const SizedBox(height: 16),
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
                      'Transaksi berulang nonaktif tidak akan dibuat otomatis setiap bulan.'),
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
