import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/models/investment_model.dart';
import '../providers/investment_providers.dart';

class AddEditInvestmentScreen extends ConsumerStatefulWidget {
  final InvestmentModel? investment;
  const AddEditInvestmentScreen({super.key, this.investment});

  bool get isEditing => investment != null;

  @override
  ConsumerState<AddEditInvestmentScreen> createState() => _AddEditInvestmentScreenState();
}

class _AddEditInvestmentScreenState extends ConsumerState<AddEditInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capitalController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _noteController = TextEditingController();
  String? _categoryId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final inv = widget.investment;
    _categoryId = inv?.categoryId;
    _date = inv?.date ?? DateTime.now();
    if (inv != null) {
      _nameController.text = inv.name;
      _capitalController.text = CurrencyFormatter.formatForInput(inv.capital);
      _currentValueController.text = CurrencyFormatter.formatForInput(inv.currentValue);
      _noteController.text = inv.note;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capitalController.dispose();
    _currentValueController.dispose();
    _noteController.dispose();
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
        const SnackBar(content: Text('Pilih jenis investasi terlebih dahulu.')),
      );
      return;
    }
    final capital = CurrencyInputFormatter.parse(_capitalController.text);
    final currentValue = CurrencyInputFormatter.parse(_currentValueController.text);
    final controller = ref.read(investmentControllerProvider.notifier);

    final success = widget.isEditing
        ? await controller.updateInvestment(InvestmentModel(
            id: widget.investment!.id,
            userId: widget.investment!.userId,
            categoryId: _categoryId!,
            name: _nameController.text.trim(),
            capital: capital,
            currentValue: currentValue,
            date: _date,
            note: _noteController.text.trim(),
          ))
        : await controller.addInvestment(
            categoryId: _categoryId!,
            name: _nameController.text.trim(),
            capital: capital,
            currentValue: currentValue,
            date: _date,
            note: _noteController.text.trim(),
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(investmentControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Investasi'),
        content: const Text('Catatan investasi ini akan dihapus secara permanen.'),
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
        .read(investmentControllerProvider.notifier)
        .deleteInvestment(widget.investment!.id);
    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(investmentControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(investmentControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider(TransactionType.investment));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Investasi' : 'Tambah Investasi'),
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
                  label: 'Nama Investasi',
                  hint: 'Contoh: Reksa Dana Pasar Uang XYZ',
                  validator: Validators.displayName,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _capitalController,
                  label: 'Modal',
                  hint: 'Rp0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (_) => Validators.amount(_capitalController.text),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _currentValueController,
                  label: 'Nilai Saat Ini',
                  hint: 'Rp0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (_) => Validators.nonNegativeAmount(_currentValueController.text),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal'),
                    child: Text(DateFormat.yMMMMd('id_ID').format(_date)),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(controller: _noteController, label: 'Catatan (opsional)', maxLines: 3),
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
