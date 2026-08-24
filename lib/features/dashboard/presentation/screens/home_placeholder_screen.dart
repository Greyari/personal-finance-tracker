import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/transaction_type.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

/// Dashboard utama aplikasi Personal Finance.
///
/// Menggunakan provider yang sudah tersedia:
/// - userProfileProvider
/// - transactionsForMonthProvider
/// - monthlyIncomeProvider
/// - budgetProgressListProvider
///
/// Tidak mengakses Firebase secara langsung. Semua data tetap melalui
/// Riverpod -> Repository -> Firestore.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final transactionsAsync = ref.watch(transactionsForMonthProvider);
    final budgetProgress = ref.watch(budgetProgressListProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsForMonthProvider);
          ref.invalidate(budgetsProvider);
          ref.invalidate(categoriesProvider(null));

          await Future.wait([
            ref.read(transactionsForMonthProvider.future),
            ref.read(budgetsProvider.future),
          ]);
        },
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => _ErrorView(
            message: 'Gagal memuat profil.\n$error',
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Profil belum tersedia.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return transactionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => _ErrorView(
                message: 'Gagal memuat transaksi.\n$error',
                onRetry: () =>
                    ref.invalidate(transactionsForMonthProvider),
              ),
              data: (transactions) {
                final income = transactions
                    .where((t) => t.type == TransactionType.income)
                    .fold<double>(
                      0,
                      (sum, transaction) => sum + transaction.amount,
                    );

                final expense = transactions
                    .where((t) => t.type == TransactionType.expense)
                    .fold<double>(
                      0,
                      (sum, transaction) => sum + transaction.amount,
                    );

                final saving = transactions
                    .where((t) => t.type == TransactionType.saving)
                    .fold<double>(
                      0,
                      (sum, transaction) => sum + transaction.amount,
                    );

                final investment = transactions
                    .where((t) => t.type == TransactionType.investment)
                    .fold<double>(
                      0,
                      (sum, transaction) => sum + transaction.amount,
                    );

                final balance = income - expense - saving - investment;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _GreetingHeader(
                      displayName: profile.displayName,
                      theme: theme,
                    ),

                    const SizedBox(height: 20),

                    _BalanceCard(
                      balance: balance,
                      income: income,
                      expense: expense,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Pemasukan',
                            amount: income,
                            icon: Icons.arrow_downward_rounded,
                            iconColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Pengeluaran',
                            amount: expense,
                            icon: Icons.arrow_upward_rounded,
                            iconColor: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Tabungan',
                            amount: saving,
                            icon: Icons.savings_outlined,
                            iconColor: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Investasi',
                            amount: investment,
                            icon: Icons.trending_up_rounded,
                            iconColor: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _SectionHeader(
                      title: 'Budget Bulan Ini',
                      actionText: 'Lihat semua',
                      onPressed: () {
                        // Akan diarahkan ke halaman budget ketika
                        // navigation budget sudah tersedia.
                      },
                    ),

                    const SizedBox(height: 10),

                    if (budgetProgress.isEmpty)
                      const _EmptyCard(
                        icon: Icons.account_balance_wallet_outlined,
                        message:
                            'Belum ada budget yang dibuat untuk akun ini.',
                      )
                    else
                      ...budgetProgress
                          .where((item) => item.budget.isActive)
                          .take(4)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BudgetProgressCard(
                                categoryName: item.categoryName,
                                categoryIcon: item.categoryIcon,
                                spent: item.spentAmount,
                                budget: item.resolvedAmount,
                                percent: item.percent,
                              ),
                            ),
                          ),

                    const SizedBox(height: 14),

                    _SectionHeader(
                      title: 'Transaksi Terakhir',
                      actionText: 'Lihat semua',
                      onPressed: () {
                        // Akan diarahkan ke transaction list ketika
                        // navigation transaksi sudah tersedia.
                      },
                    ),

                    const SizedBox(height: 10),

                    if (transactions.isEmpty)
                      const _EmptyCard(
                        icon: Icons.receipt_long_outlined,
                        message:
                            'Belum ada transaksi pada bulan ini.',
                      )
                    else
                      ...transactions
                          .take(5)
                          .map(
                            (transaction) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TransactionTile(
                                transaction: transaction,
                                categoryName:
                                    _findCategoryName(
                                  ref,
                                  transaction.categoryId,
                                ),
                                categoryIcon:
                                    _findCategoryIcon(
                                  ref,
                                  transaction.categoryId,
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 16),

                    _DailySpendingCard(
                      expense: expense,
                      transactionCount: transactions.length,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _findCategoryName(
    WidgetRef ref,
    String categoryId,
  ) {
    final categories =
        ref.watch(categoriesProvider(null)).value ?? const [];

    for (final category in categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }

    return 'Kategori lainnya';
  }

  String _findCategoryIcon(
    WidgetRef ref,
    String categoryId,
  ) {
    final categories =
        ref.watch(categoriesProvider(null)).value ?? const [];

    for (final category in categories) {
      if (category.id == categoryId) {
        return category.icon;
      }
    }

    return 'other';
  }
}

class _GreetingHeader extends StatelessWidget {
  final String displayName;
  final ThemeData theme;

  const _GreetingHeader({
    required this.displayName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final greeting = switch (hour) {
      >= 5 && < 12 => 'Selamat pagi',
      >= 12 && < 18 => 'Selamat siang',
      >= 18 && < 23 => 'Selamat malam',
      _ => 'Halo',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          displayName.isEmpty ? 'Pengguna' : displayName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(DateTime.now()),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo Bulan Ini',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatRupiah(balance),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniAmount(
                    label: 'Masuk',
                    amount: income,
                    icon: Icons.add_circle_outline,
                  ),
                ),
                Expanded(
                  child: _MiniAmount(
                    label: 'Keluar',
                    amount: expense,
                    icon: Icons.remove_circle_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAmount extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;

  const _MiniAmount({
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                _formatRupiah(amount),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(
                icon,
                size: 19,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatRupiah(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final double spent;
  final double budget;
  final double percent;

  const _BudgetProgressCard({
    required this.categoryName,
    required this.categoryIcon,
    required this.spent,
    required this.budget,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progress = percent.clamp(0.0, 1.0);
    final isOverBudget = percent > 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                _CategoryIcon(icon: categoryIcon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    categoryName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOverBudget
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatRupiah(spent),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'dari ${_formatRupiah(budget)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic transaction;
  final String categoryName;
  final String categoryIcon;

  const _TransactionTile({
    required this.transaction,
    required this.categoryName,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;

    final amountPrefix = isIncome ? '+' : '-';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: _CategoryIcon(icon: categoryIcon),
        title: Text(
          transaction.description.isEmpty
              ? categoryName
              : transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$categoryName • ${_formatShortDate(transaction.date)}',
        ),
        trailing: Text(
          '$amountPrefix${_formatRupiah(transaction.amount)}',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isIncome
                ? Colors.green
                : isExpense
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _DailySpendingCard extends StatelessWidget {
  final double expense;
  final int transactionCount;

  const _DailySpendingCard({
    required this.expense,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final now = DateTime.now();
    final daysElapsed = now.day;

    final dailyAverage =
        daysElapsed <= 0 ? 0.0 : expense / daysElapsed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              child: Icon(
                Icons.speed_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rata-rata Pengeluaran Harian',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRupiah(dailyAverage),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$transactionCount transaksi bulan ini',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onPressed;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(actionText),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyCard({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 28,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 42,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String icon;

  const _CategoryIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 21,
      child: Icon(
        _iconForCategory(icon),
        size: 20,
      ),
    );
  }

  IconData _iconForCategory(String icon) {
    return switch (icon.toLowerCase()) {
      'food' || 'makanan' => Icons.restaurant_outlined,
      'transport' || 'transportation' => Icons.directions_car_outlined,
      'shopping' => Icons.shopping_bag_outlined,
      'health' => Icons.medical_services_outlined,
      'education' => Icons.school_outlined,
      'home' => Icons.home_outlined,
      'bills' => Icons.receipt_long_outlined,
      'entertainment' => Icons.movie_outlined,
      'salary' => Icons.work_outline,
      'church' || 'donation' => Icons.volunteer_activism_outlined,
      'saving' || 'savings' => Icons.savings_outlined,
      'investment' => Icons.trending_up_rounded,
      _ => Icons.category_outlined,
    };
  }
}

String _formatRupiah(double value) {
  final rounded = value.round().abs();
  final digits = rounded.toString();

  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }

    buffer.write(digits[i]);
  }

  final prefix = value < 0 ? '-Rp ' : 'Rp ';

  return '$prefix${buffer.toString()}';
}

String _formatDate(DateTime date) {
  const days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return '${days[date.weekday - 1]}, ${date.day} '
      '${months[date.month - 1]} ${date.year}';
}

String _formatShortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
