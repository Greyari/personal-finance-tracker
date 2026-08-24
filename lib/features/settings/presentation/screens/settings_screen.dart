import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/screens/category_list_screen.dart';
import '../../../dashboard/presentation/screens/financial_health_screen.dart';
import '../../../dashboard/presentation/screens/six_month_projection_screen.dart';
import '../../../recurring/presentation/screens/recurring_list_screen.dart';
import '../../../reports/presentation/screens/monthly_report_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          profileAsync.when(
            data: (profile) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(profile?.displayName ?? '-'),
              subtitle: Text(profile?.email ?? '-'),
            ),
            loading: () => const ListTile(title: Text('Memuat profil...')),
            error: (e, _) => ListTile(title: Text('Gagal memuat profil: $e')),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Kelola Kategori'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoryListScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Transaksi Berulang'),
            subtitle: const Text('Termasuk Gereja 10% dan tagihan bulanan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecurringListScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Laporan Bulanan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timeline_outlined),
            title: const Text('Proyeksi 6 Bulan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SixMonthProjectionScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Financial Health'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FinancialHealthScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Keluar', style: TextStyle(color: AppColors.error)),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
