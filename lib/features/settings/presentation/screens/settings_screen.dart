import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/cover_image_picker.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/screens/category_list_screen.dart';
import '../../../dashboard/presentation/screens/financial_health_screen.dart';
import '../../../recurring/presentation/screens/recurring_list_screen.dart';
import '../../../reports/presentation/screens/monthly_report_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Keluar dari Akun',
      message: 'Apakah Anda yakin ingin keluar dari akun RERO?',
      confirmLabel: 'Keluar',
      cancelLabel: 'Batal',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  Future<void> _pickCustomWallpaper(BuildContext context, WidgetRef ref) async {
    final isDark = AppColors.isDark(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131826) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Wallpaper Sendiri',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  'Gunakan foto favorit dari memori HP kamu',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
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
                  'Ambil dari Kamera',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  'Potret foto baru secara langsung',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              if (ref.read(appWallpaperProvider).customFilePath != null) ...[
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: AppColors.expense(context).withValues(alpha: isDark ? 0.12 : 0.08),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.expense(context).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: AppColors.expense(context)),
                  ),
                  title: Text(
                    'Hapus Foto Wallpaper',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.expense(context),
                    ),
                  ),
                  subtitle: Text(
                    'Kembalikan ke wallpaper default Ghibli Klasik',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteCustomWallpaper(context, ref);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final path = await CoverImagePicker.pickWallpaper(source);
      if (!context.mounted) return;
      if (path != null) {
        await ref.read(appWallpaperProvider.notifier).setCustomWallpaper(path);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto berhasil dipasang sebagai wallpaper!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteCustomWallpaper(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Hapus Foto Kustom',
      message: 'Apakah Anda yakin ingin menghapus foto ini? Latar belakang akan dikembalikan ke Ghibli Klasik.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true && context.mounted) {
      final customPath = ref.read(appWallpaperProvider).customFilePath;
      if (customPath != null) {
        final file = File(customPath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
      await ref.read(appWallpaperProvider.notifier).clearCustomWallpaper();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto kustom berhasil dihapus. Wallpaper kembali ke Ghibli Klasik.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final profileAsync = ref.watch(userProfileProvider);
    final currentThemeMode = ref.watch(themeNotifierProvider);
    final currentWallpaper = ref.watch(appWallpaperProvider);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 88),
          children: [
          // Profile Card
          profileAsync.when(
            data: (profile) => GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 22,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (profile != null && profile.displayName.isNotEmpty)
                            ? profile.displayName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName ?? 'Pengguna',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile?.email ?? '-',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const GlassCard(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => GlassCard(
              padding: const EdgeInsets.all(18),
              child: Text('Gagal memuat profil: $e'),
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 18),

          // Theme Selection Section
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Tema Tampilan',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('Terang'),
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('Gelap'),
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('Sistem'),
                      icon: Icon(Icons.brightness_auto_rounded, size: 18),
                    ),
                  ],
                  selected: {currentThemeMode},
                  onSelectionChanged: (Set<ThemeMode> selected) {
                    ref.read(themeNotifierProvider.notifier).setThemeMode(selected.first);
                  },
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 18),

          // Wallpaper Background Section
          GlassCard(
            padding: const EdgeInsets.all(18),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wallpaper_rounded, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wallpaper Latar Belakang',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _pickCustomWallpaper(context, ref),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentWallpaper.customFilePath != null
                                  ? Icons.autorenew_rounded
                                  : Icons.add_photo_alternate_rounded,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              currentWallpaper.customFilePath != null ? 'Ganti Foto' : 'Upload Foto',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih gaya seni visual atau upload foto kamu sendiri:',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      // If custom file exists, show custom card first!
                      if (currentWallpaper.customFilePath != null) ...[
                        _buildWallpaperItem(
                          context: context,
                          ref: ref,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          label: 'Foto Kustom',
                          isSelected: currentWallpaper.wallpaper == AppWallpaper.custom,
                          fileImage: File(currentWallpaper.customFilePath!),
                          onDelete: () => _confirmDeleteCustomWallpaper(context, ref),
                          onTap: () => ref.read(appWallpaperProvider.notifier).setWallpaper(AppWallpaper.custom),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Presets (excluding custom, which is handled above)
                      ...AppWallpaper.values
                          .where((wp) => wp != AppWallpaper.custom)
                          .map((wp) {
                        final isSelected = currentWallpaper.wallpaper == wp;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildWallpaperItem(
                            context: context,
                            ref: ref,
                            isDark: isDark,
                            primaryColor: primaryColor,
                            label: _formatWallpaperLabel(wp),
                            isSelected: isSelected,
                            assetPath: wp.assetPath,
                            onTap: () => ref.read(appWallpaperProvider.notifier).setWallpaper(wp),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 18),

          // Menu Options
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            borderRadius: 22,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.category_outlined,
                  title: 'Kelola Kategori',
                  subtitle: 'Tambah dan ubah kategori transaksi',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CategoryListScreen()),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: isDark ? const Color(0x1AFFFFFF) : const Color(0x10000000),
                ),
                _SettingsTile(
                  icon: Icons.repeat_rounded,
                  title: 'Transaksi Berulang',
                  subtitle: 'Pengeluaran/pemasukan rutin bulanan',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecurringListScreen()),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: isDark ? const Color(0x1AFFFFFF) : const Color(0x10000000),
                ),
                _SettingsTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Laporan Bulanan',
                  subtitle: 'Analisis pemasukan, pengeluaran & grafik',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: isDark ? const Color(0x1AFFFFFF) : const Color(0x10000000),
                ),
                _SettingsTile(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Financial Health',
                  subtitle: 'Rasio tabungan, investasi & pengeluaran',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FinancialHealthScreen()),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // Logout Button
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: 18,
            onTap: () => _confirmSignOut(context, ref),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.expense(context).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.expense(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Keluar dari Akun',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.expense(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.expense(context),
                  size: 20,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 450.ms),
        ],
      ),
    ),
  );
  }

  Widget _buildWallpaperItem({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required Color primaryColor,
    required String label,
    required bool isSelected,
    String? assetPath,
    File? fileImage,
    VoidCallback? onDelete,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 104,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: isDark ? const Color(0xFF0F131D) : const Color(0xFFE2E8F0),
                    child: fileImage != null
                        ? Image.file(
                            fileImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image_rounded, size: 24),
                            ),
                          )
                        : assetPath != null
                            ? Image.asset(
                                assetPath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image_rounded, size: 24),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.layers_clear_rounded,
                                  size: 28,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                  ),
                ),
                if (onDelete != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.78),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                          color: Color(0xFFF87171),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
                color: isSelected
                    ? primaryColor
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatWallpaperLabel(AppWallpaper wp) {
    switch (wp) {
      case AppWallpaper.ghibliClassic:
        return 'Ghibli Klasik';
      case AppWallpaper.custom:
        return 'Upload Sendiri';
      case AppWallpaper.none:
        return 'Polos';
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.5,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      onTap: onTap,
    );
  }
}
