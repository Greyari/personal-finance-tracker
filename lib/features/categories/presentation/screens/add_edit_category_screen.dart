import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_widgets.dart';
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
      showGlassSnackBar(
        context,
        widget.isEditing ? 'Kategori berhasil diperbarui' : 'Kategori berhasil ditambahkan',
      );
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(categoryControllerProvider).error;
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
    final controllerState = ref.watch(categoryControllerProvider);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Kategori' : 'Tambah Kategori',
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
                      AppTextField(
                        controller: _nameController,
                        label: 'Nama Kategori',
                        hint: 'Contoh: Makanan, Transport, Gaji',
                        validator: Validators.displayName,
                      ),
                      const SizedBox(height: 18),
                      if (!widget.isEditing) ...[
                        Text(
                          'Tipe Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            TransactionType.expense,
                            TransactionType.income,
                            TransactionType.investment,
                          ].map((type) {
                            final isSelected = type == _type;
                            return InkWell(
                              onTap: () => setState(() => _type = type),
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
                      ],
                      Text(
                        'Pilih Ikon Kategori',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: CategoryIcons.allKeys.map((key) {
                          final isSelected = key == _icon;
                          return InkWell(
                            onTap: () => setState(() => _icon = key),
                            borderRadius: BorderRadius.circular(24),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? primaryColor.withValues(alpha: 0.22)
                                    : (isDark ? AppColors.glassFillDark : AppColors.glassFillLight),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Icon(
                                CategoryIcons.resolve(key),
                                color: isSelected ? primaryColor : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                size: 22,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Simpan Kategori',
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
