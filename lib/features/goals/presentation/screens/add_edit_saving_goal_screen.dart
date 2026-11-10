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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CoverOption(
                icon: Icons.photo_library_outlined,
                label: 'Pilih dari Galeri',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCover(ImageSource.gallery);
                },
              ),
              _CoverOption(
                icon: Icons.photo_camera_outlined,
                label: 'Ambil dengan Kamera',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCover(ImageSource.camera);
                },
              ),
              _CoverOption(
                icon: Icons.auto_awesome_outlined,
                label: 'Pakai gambar contoh',
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _coverPath = 'assets/images/goals/dream_car.png');
                },
              ),
              if (_coverPath != null)
                _CoverOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Hapus foto',
                  color: AppColors.expenseDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _coverPath = null);
                  },
                ),
            ],
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


class _CoverOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _CoverOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final c = color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final iconColor = color ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: GoogleFonts.inter(fontSize: 15, color: c)),
      onTap: onTap,
    );
  }
}