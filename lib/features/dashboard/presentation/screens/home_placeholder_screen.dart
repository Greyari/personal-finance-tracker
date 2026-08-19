import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

/// TEMPORARY placeholder shown right after login.
///
/// The real dashboard (income/expense totals, budget progress, daily
/// spending limit, etc.) is built in Phase 3, per the phased plan. This
/// screen exists only so the full auth flow — register, login, profile
/// load, logout — can be tested end-to-end in Phase 1.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: profileAsync.when(
          data: (profile) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              profile == null
                  ? 'Profil belum tersedia.'
                  : 'Selamat datang, ${profile.displayName}!\n\n'
                      'Dashboard, transaksi, dan budget akan dibangun di fase berikutnya.',
              textAlign: TextAlign.center,
            ),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Terjadi kesalahan: $e'),
        ),
      ),
    );
  }
}
