import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/cover_image_picker.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../../shared/widgets/goal_cover_image.dart';
import '../../data/models/saving_goal_model.dart';
import '../providers/saving_goal_providers.dart';

class AddEditSavingGoalScreen extends ConsumerStatefulWidget {
  final SavingGoalModel? goal;
  const AddEditSavingGoalScreen({super.key, this.goal});

  bool get isEditing => goal != null;

  @override
  ConsumerState<AddEditSavingGoalScreen> createState() => _AddEditSavingGoalScreenState();
}

class _AddEditSavingGoalScreenState extends ConsumerState<AddEditSavingGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String? _coverPath;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetController.text = CurrencyFormatter.formatForInput(widget.goal!.targetAmount);
      _coverPath = widget.goal!.coverImagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickCover(ImageSource source) async {
    try {
      final path = await CoverImagePicker.pick(source);
      if (path != null && mounted) setState(() => _coverPath = path);
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(context, 'Gagal mengambil foto. Coba lagi.', isError: true);
      }
    }
  }

  void _showCoverOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131826) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Foto Cover Target',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tentukan foto visual untuk target tabunganmu',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.photo_library_rounded, color: isDark ? Colors.white : Colors.black),
                    ),
                    title: Text(
                      'Pilih dari Galeri',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: Text(
                      'Gunakan foto impian dari memori HP kamu',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickCover(ImageSource.gallery);
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt_rounded, color: isDark ? Colors.white : Colors.black),
                    ),
                    title: Text(
                      'Ambil dengan Kamera',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: Text(
                      'Potret foto target impianmu secara langsung',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickCover(ImageSource.camera);
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF34D399)),
                    ),
                    title: Text(
                      'Pakai Gambar Contoh',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    subtitle: Text(
                      'Gunakan ilustrasi mobil impian 3D default',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _coverPath = 'assets/images/goals/dream_car.png');
                    },
                  ),
                  if (_coverPath != null) ...[
                    const SizedBox(height: 10),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: (isDark ? AppColors.expenseDark : AppColors.expenseLight)
                          .withValues(alpha: isDark ? 0.10 : 0.06),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.expenseDark : AppColors.expenseLight)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                        ),
                      ),
                      title: Text(
                        'Hapus Foto Cover',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: isDark ? AppColors.expenseDark : AppColors.expenseLight,
                        ),
                      ),
                      subtitle: Text(
                        'Kembalikan ke tampilan cover minimalis',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _coverPath = null);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final targetAmount = CurrencyInputFormatter.parse(_targetController.text);
    final controller = ref.read(savingGoalControllerProvider.notifier);

    final success = widget.isEditing
        ? await controller.updateGoal(SavingGoalModel(
            id: widget.goal!.id,
            userId: widget.goal!.userId,
            name: _nameController.text.trim(),
            targetAmount: targetAmount,
            currentAmount: widget.goal!.currentAmount,
            coverImagePath: _coverPath,
          ))
        : await controller.addGoal(
            name: _nameController.text.trim(),
            targetAmount: targetAmount,
            coverImagePath: _coverPath,
          );

    if (success && mounted) {
      showGlassSnackBar(
        context,
        widget.isEditing ? 'Target berhasil diperbarui' : 'Target tabungan berhasil dibuat',
      );
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      final error = ref.read(savingGoalControllerProvider).error;
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
    final controllerState = ref.watch(savingGoalControllerProvider);

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Target Tabungan' : 'Target Tabungan Baru',
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
                GestureDetector(
                  onTap: _showCoverOptions,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: SizedBox(
                      height: 180,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GoalCoverImage(path: _coverPath),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.backgroundDark.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                            child: Row(
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined,
                                    color: AppColors.primaryDark, size: 20),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  _coverPath == null ? 'Tambah foto cover' : 'Ganti foto cover',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: AppSpacing.sm),
                GlassCard(                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: 'Nama Target Tabungan',
                        hint: 'Contoh: Dana Darurat, Liburan, Gadget',
                        validator: Validators.displayName,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _targetController,
                        label: 'Target Jumlah',
                        hint: 'Rp0',
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: (_) => Validators.amount(_targetController.text),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Simpan Target',
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