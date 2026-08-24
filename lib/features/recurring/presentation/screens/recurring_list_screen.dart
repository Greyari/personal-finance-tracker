import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../providers/recurring_providers.dart';
import 'add_edit_recurring_screen.dart';

class RecurringListScreen extends ConsumerWidget {
  const RecurringListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi Berulang')),
      body: recurringAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada transaksi berulang.\n'
                  'Tekan tombol + untuk menambahkan, misalnya "Internet Rp100.000/bulan".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          final categories = categoriesAsync.value ?? const [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final r = items[index];
              final matches = categories.where((c) => c.id == r.categoryId);
              final category = matches.isNotEmpty ? matches.first : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(CategoryIcons.resolve(category?.icon ?? 'other')),
                    ),
                    title: Text(r.name),
                    subtitle: Text(
                      r.isPercentage
                          ? '${r.value.toStringAsFixed(0)}% dari pendapatan · Bulanan'
                          : 'Nominal tetap · Bulanan',
                    ),
                    trailing: Switch(
                      value: r.isActive,
                      onChanged: (value) =>
                          ref.read(recurringControllerProvider.notifier).setActive(r.id, value),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AddEditRecurringScreen(recurring: r)),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditRecurringScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
