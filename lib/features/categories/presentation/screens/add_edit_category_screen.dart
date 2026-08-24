import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/category_model.dart';
import '../providers/category_providers.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final CategoryModel? category;
  final TransactionType? initialType;

  const AddEditCategoryScreen({super.key, this.category, this.initialType});

  bool get isEditing => category != null;

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late TransactionType _type;
  String _icon = 'other';

  @override
  void initState() {
    super.initState();
    _type = widget.category?.type ?? widget.initialType ?? TransactionType.expense;
    _icon = widget.category?.icon ?? 'other';
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(categoryControllerProvider.notifier);
    final success = widget.isEditing
        ? await controller.updateCategory(
            CategoryModel(
              id: widget.category!.id,
              name: _nameController.text.trim(),
              type: _type,
              icon: _icon,
              isDefault: widget.category!.isDefault,
            ),
          )
        : await controller.addCategory(
            name: _nameController.text.trim(),
            type: _type,
            icon: _icon,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(categoryControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(categoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Kategori' : 'Tambah Kategori'),
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
                  label: 'Nama Kategori',
                  validator: Validators.displayName,
                ),
                const SizedBox(height: 16),
                // Type can only be chosen when creating a new category.
                // Changing an existing category's type would silently
                // misclassify every past transaction that already uses it,
                // so editing keeps the original type fixed.
                if (!widget.isEditing) ...[
                  const Text('Tipe', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TransactionType.values.map((type) {
                      final isSelected = type == _type;
                      return ChoiceChip(
                        label: Text(type.label),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _type = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Ikon', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryIcons.allKeys.map((key) {
                    final isSelected = key == _icon;
                    return InkWell(
                      onTap: () => setState(() => _icon = key),
                      borderRadius: BorderRadius.circular(24),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.background,
                        child: Icon(
                          CategoryIcons.resolve(key),
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
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
