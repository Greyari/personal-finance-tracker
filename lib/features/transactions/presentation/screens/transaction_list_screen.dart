import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_providers.dart';
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsForMonthProvider);
    // Watching all categories (type: null) so the list can resolve each
    // transaction's category name/icon without a separate query per row.
    final categoriesAsync = ref.watch(categoriesProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: Column(
        children: [
          const MonthSelector(),
          const Divider(height: 1),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const _EmptyState();
                }
                final categories = categoriesAsync.value ?? const [];
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final category = categories
                        .where((c) => c.id == tx.categoryId)
                        .cast()
                        .firstOrNull;
                    return _TransactionTile(
                      transaction: tx,
                      categoryName: category?.name,
                      categoryIcon: category?.icon,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String? categoryName;
  final String? categoryIcon;

  const _TransactionTile({
    required this.transaction,
    this.categoryName,
    this.categoryIcon,
  });

  Color _amountColor() {
    switch (transaction.type) {
      case TransactionType.income:
        return AppColors.success;
      case TransactionType.expense:
        return AppColors.error;
      case TransactionType.saving:
      case TransactionType.investment:
        return AppColors.primary;
    }
  }

  String _sign() {
    switch (transaction.type) {
      case TransactionType.income:
        return '+';
      case TransactionType.expense:
        return '-';
      case TransactionType.saving:
      case TransactionType.investment:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd('id_ID').format(transaction.date);
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddEditTransactionScreen(transaction: transaction),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.background,
        child: Icon(CategoryIcons.resolve(categoryIcon ?? 'other'), color: AppColors.textPrimary),
      ),
      title: Text(categoryName ?? transaction.type.label),
      subtitle: Text(
        transaction.description.isEmpty ? dateLabel : '${transaction.description} · $dateLabel',
      ),
      trailing: Text(
        '${_sign()}${CurrencyFormatter.format(transaction.amount)}',
        style: TextStyle(color: _amountColor(), fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Belum ada transaksi di bulan ini.\nTekan tombol + untuk menambahkan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
