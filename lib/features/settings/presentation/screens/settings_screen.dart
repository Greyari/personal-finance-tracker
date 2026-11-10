import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
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
      message: 'Apakah Anda yakin ingin keluar dari akun Personal Finance?',
      confirmLabel: 'Keluar',
      cancelLabel: 'Batal',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final profileAsync = ref.watch(userProfileProvider);
    final currentThemeMode = ref.watch(themeNotifierProvider);
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
      body: ListView(
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
    );
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
