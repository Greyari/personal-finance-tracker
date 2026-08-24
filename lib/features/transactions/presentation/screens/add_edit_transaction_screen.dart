import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_providers.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

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

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx?.type ?? TransactionType.expense;
    _categoryId = tx?.categoryId;
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
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
      );
      return;
    }
    final userId = ref.read(authStateProvider).value?.uid;
    if (userId == null) return;

    final amount = CurrencyInputFormatter.parse(_amountController.text);
    final controller = ref.read(transactionControllerProvider.notifier);

    final success = widget.isEditing
        ? await controller.updateTransaction(
            TransactionModel(
              id: widget.transaction!.id,
              userId: userId,
              type: _type,
              categoryId: _categoryId!,
              amount: amount,
              description: _descriptionController.text.trim(),
              date: _date,
            ),
          )
        : await controller.addTransaction(
            TransactionModel(
              id: '',
              userId: userId,
              type: _type,
              categoryId: _categoryId!,
              amount: amount,
              description: _descriptionController.text.trim(),
              date: _date,
            ),
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(transactionControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Transaksi ini akan dihapus secara permanen.'),
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
    final success = await ref
        .read(transactionControllerProvider.notifier)
        .deleteTransaction(widget.transaction!.id);
    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(transactionControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(transactionControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider(_type));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Transaksi' : 'Tambah Transaksi'),
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
                _TypeSelector(
                  selected: _type,
                  onChanged: (type) => setState(() {
                    _type = type;
                    // Categories are type-specific, so switching type
                    // invalidates whatever was previously selected.
                    _categoryId = null;
                  }),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _amountController,
                  label: 'Jumlah',
                  hint: 'Rp0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (_) => Validators.amount(_amountController.text),
                ),
                const SizedBox(height: 16),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    value:
                        categories.any((c) => c.id == _categoryId) ? _categoryId : null,
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
                AppTextField(
                  controller: _descriptionController,
                  label: 'Deskripsi (opsional)',
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal'),
                    child: Text(DateFormat.yMMMMd('id_ID').format(_date)),
                  ),
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

class _TypeSelector extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: TransactionType.values.map((type) {
        final isSelected = type == selected;
        return ChoiceChip(
          label: Text(type.label),
          selected: isSelected,
          onSelected: (_) => onChanged(type),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
