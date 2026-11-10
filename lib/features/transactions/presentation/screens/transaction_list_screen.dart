import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../goals/presentation/providers/saving_goal_providers.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_providers.dart';
import 'add_edit_transaction_screen.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  TransactionType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final transactionsAsync = ref.watch(transactionsForMonthProvider);
    final categoriesAsync = ref.watch(categoriesProvider(null));
    final goalsAsync = ref.watch(savingGoalsProvider);
    final summary = ref.watch(monthlySummaryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Daftar Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          GlassSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(transactionsForMonthProvider);
              ref.invalidate(savingGoalsProvider);
              ref.invalidate(categoriesProvider(null));
              await Future.delayed(const Duration(milliseconds: 500));
            },
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: MonthSelector(),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 10),
                _MonthCashFlowBanner(summary: summary)
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 8),
                _FilterBar(
                  selected: _selectedFilter,
                  onSelected: (type) => setState(() => _selectedFilter = type),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 10),
              ],
            ),
          ),
          ...transactionsAsync.when(
            data: (allTransactions) {
              final filtered = _selectedFilter == null
                  ? allTransactions
                  : allTransactions.where((t) => t.type == _selectedFilter).toList();

              if (filtered.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: _EmptyState(filter: _selectedFilter)),
                  ),
                ];
              }

              final categories = categoriesAsync.value ?? const [];
              final goals = goalsAsync.value ?? const [];

              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = filtered[index];
                        final category = categories
                            .where((c) => c.id == tx.categoryId)
                            .firstOrNull;
                        final goal = goals.where((g) => g.id == tx.goalId).firstOrNull;
                        final isSavingTx = tx.type == TransactionType.saving;

                        return _TransactionTile(
                          transaction: tx,
                          categoryName: isSavingTx && goal != null
                              ? goal.name
                              : (category?.name ?? (isSavingTx ? 'Tabungan (Goal)' : null)),
                          categoryIcon: isSavingTx ? 'saving_goal' : category?.icon,
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 30 * index.clamp(0, 10)),
                              duration: 250.ms,
                            );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
              ];
            },
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Terjadi kesalahan: $e')),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: GlassCircularFab(
        heroTag: 'fab_add_transaction',
        tooltip: 'Catat Transaksi',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddEditTransactionScreen(initialType: _selectedFilter),
          ),
        ),
      ),
    );
  }
}

class _MonthCashFlowBanner extends StatelessWidget {
  final MonthlySummary summary;
  const _MonthCashFlowBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final net = summary.sisa;
    final isPositive = net >= 0;
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 20,
        child: Row(
          children: [
            // Masuk
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, size: 14, color: incomeColor),
                      const SizedBox(width: 4),
                      Text(
                        'Masuk',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatter.format(summary.totalIncome),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: incomeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 32,
              width: 1,
              color: isDark ? const Color(0x22FFFFFF) : const Color(0x18000000),
            ),
            const SizedBox(width: 12),
            // Keluar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 14, color: expenseColor),
                      const SizedBox(width: 4),
                      Text(
                        'Keluar',
                        style: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatter.format(summary.totalOutflow),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: expenseColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 32,
              width: 1,
              color: isDark ? const Color(0x22FFFFFF) : const Color(0x18000000),
            ),
            const SizedBox(width: 12),
            // Sisa Saldo Sekarang
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sisa Saldo',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${isPositive ? '+' : ''}${CurrencyFormatter.format(net)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isPositive
                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                            : expenseColor,
                      ),
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

class _FilterBar extends StatelessWidget {
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onSelected;

  const _FilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip(
            label: 'Semua',
            isSelected: selected == null,
            color: primaryColor,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Uang Masuk',
            isSelected: selected == TransactionType.income,
            color: incomeColor,
            onTap: () => onSelected(
              selected == TransactionType.income ? null : TransactionType.income,
            ),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Uang Keluar',
            isSelected: selected == TransactionType.expense,
            color: expenseColor,
            onTap: () => onSelected(
              selected == TransactionType.expense ? null : TransactionType.expense,
            ),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Tabungan',
            isSelected: selected == TransactionType.saving,
            color: primaryColor,
            onTap: () => onSelected(
              selected == TransactionType.saving ? null : TransactionType.saving,
            ),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Investasi',
            isSelected: selected == TransactionType.investment,
            color: primaryColor,
            onTap: () => onSelected(
              selected == TransactionType.investment ? null : TransactionType.investment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : null,
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final Color amountColor;
    final String sign;

    switch (transaction.type) {
      case TransactionType.income:
        amountColor = AppColors.income(context);
        sign = '+';
        break;
      case TransactionType.expense:
        amountColor = AppColors.expense(context);
        sign = '-';
        break;
      case TransactionType.saving:
        amountColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
        sign = '-';
        break;
      case TransactionType.investment:
        amountColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
        sign = '-';
        break;
    }

    final dateLabel = DateFormat.yMMMd('id_ID').format(transaction.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 18,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddEditTransactionScreen(transaction: transaction),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: amountColor.withValues(alpha: 0.25), width: 1),
              ),
              child: Icon(
                CategoryIcons.resolve(categoryIcon ?? 'other'),
                color: amountColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          categoryName ?? transaction.type.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.goalId != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                size: 10.5,
                                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                              ),
                              const SizedBox(width: 2.5),
                              Text(
                                'Goal',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.description.isEmpty
                        ? dateLabel
                        : '${transaction.description} · $dateLabel',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$sign${CurrencyFormatter.format(transaction.amount)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final TransactionType? filter;
  const _EmptyState({this.filter});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    String message = 'Belum ada transaksi di bulan ini.\nTekan tombol di bawah untuk mencatat transaksi.';
    if (filter == TransactionType.income) {
      message = 'Belum ada catatan uang masuk (pemasukan) di bulan ini.';
    } else if (filter == TransactionType.expense) {
      message = 'Belum ada catatan uang keluar (pengeluaran) di bulan ini.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.5,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
