import 'dart:math' as math;
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../../../shared/widgets/goal_card_slider.dart';
import '../../../../shared/widgets/month_selector.dart';
import '../../../../shared/widgets/note_sticky_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../goals/presentation/providers/saving_goal_providers.dart';
import '../../../goals/presentation/screens/add_edit_saving_goal_screen.dart';
import '../../../goals/presentation/screens/saving_goal_detail_screen.dart';
import '../../../main/presentation/screens/main_shell.dart';
import '../../../reports/presentation/screens/monthly_report_screen.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/screens/add_edit_transaction_screen.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../providers/dashboard_providers.dart';
import '../providers/financial_health_provider.dart';
import 'financial_health_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    ref.watch(userDirectorySyncProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final transactionsAsync = ref.watch(transactionsForMonthProvider);
    final categoriesAsync = ref.watch(categoriesProvider(null));
    final goalsAsync = ref.watch(savingGoalsProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final budgetUsedPercent = ref.watch(budgetUsedPercentProvider);
    final dailyLimit = ref.watch(dailySpendingLimitProvider);
    final health = ref.watch(financialHealthProvider);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: const FloatingNoteButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_wallet_rounded, size: 20, color: primaryColor),
            ),
            const SizedBox(width: 10),
            Text(
              'Personal Finance',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.3,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bar_chart_rounded, size: 20, color: primaryColor),
            ),
            tooltip: 'Laporan Bulanan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Elastic pull-to-refresh that physically moves the whole page down
          GlassSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(transactionsForMonthProvider);
              ref.invalidate(categoriesProvider(null));
              ref.invalidate(savingGoalsProvider);
              ref.invalidate(userProfileProvider);
              await Future<void>.delayed(const Duration(milliseconds: 600));
            },
          ),

          // Main Dashboard Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // User Greeting Header
                profileAsync.when(
                  skipLoadingOnRefresh: true,
                  data: (profile) => Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
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
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (profile != null && profile.displayName.isNotEmpty)
                                ? profile.displayName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${profile?.displayName ?? 'Sobat'} 👋',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ringkasan arus keuangan bulan ini',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _DashboardChatButton(),
                    ],
                  ),
                  loading: () => Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceHighDark : AppColors.surfaceHighLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceHighDark : AppColors.surfaceHighLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 180,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceHighDark : AppColors.surfaceHighLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _DashboardChatButton(),
                    ],
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 12),

                // Prominent Interactive Cat Companion Card ("Kucing Cuan")
                const _InteractiveCatHeroCard().animate().fadeIn(duration: 320.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 14),

                // Month Selector
                const MonthSelector().animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 14),

                // Premium Glass Hero Card (Saldo Bulan Ini)
                _FuturisticBalanceCard(
                  sisa: summary.sisa,
                  income: summary.totalIncome,
                  expense: summary.totalOutflow,
                  dailyLimit: dailyLimit,
                  hideBalance: _hideBalance,
                  onToggleHide: () => setState(() => _hideBalance = !_hideBalance),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.12, end: 0),
                const SizedBox(height: 16),

                // Quick Action Buttons (Masuk, Keluar, Tabungan)
                _QuickActionRow(
                  onIncomeTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditTransactionScreen(initialType: TransactionType.income),
                    ),
                  ),
                  onExpenseTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditTransactionScreen(initialType: TransactionType.expense),
                    ),
                  ),
                  onSavingTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditTransactionScreen(initialType: TransactionType.saving),
                    ),
                  ),
                ).animate().fadeIn(duration: 450.ms),
                const SizedBox(height: 18),

                // Cash Flow Distribution Bar
                _CashFlowDistributionBar(summary: summary)
                    .animate()
                    .fadeIn(duration: 480.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 18),

                // 2x2 Stat Cards (Pemasukan, Pengeluaran, Tabungan, Investasi)
                _SummaryGrid(summary: summary, hideNumbers: _hideBalance)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),

                // Saving Goals Slider (Sesuai Referensi 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 18,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target Tabungan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => ref.read(mainNavIndexProvider.notifier).state = 2,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Semua',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                goalsAsync.when(
                  skipLoadingOnRefresh: true,
                  data: (goals) => GoalCardSlider(
                    goals: goals,
                    onGoalTap: (goal) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SavingGoalDetailScreen(goal: goal),
                        ),
                      );
                    },
                    onAddGoalTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddEditSavingGoalScreen(),
                        ),
                      );
                    },
                  ),
                  loading: () => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ).animate().fadeIn(duration: 520.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 20),

                // Grafik Tren Arus Kas Interaktif (fl_chart)
                _FinancialTrendsChart(
                  transactions: transactionsAsync.value ?? const [],
                ).animate().fadeIn(duration: 530.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 20),

                // Recent Transactions Section
                transactionsAsync.when(
                  skipLoadingOnRefresh: true,
                  data: (transactions) => _RecentTransactionsSection(
                    transactions: transactions.take(5).toList(),
                    categories: categoriesAsync.value ?? const [],
                    hideNumbers: _hideBalance,
                    onViewAll: () => ref.read(mainNavIndexProvider.notifier).state = 1,
                  ),
                  loading: () => const GlassCard(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Text('Gagal memuat transaksi: $e'),
                  ),
                ).animate().fadeIn(duration: 550.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 20),

                // Budget & Financial Health Card
                _BudgetHealthCard(
                  budgetUsedPercent: budgetUsedPercent,
                  health: health,
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Futuristic Frosted Glass Balance Card with glowing aesthetic,
/// eye hide/show toggle, and integrated income/expense pills.
class _FuturisticBalanceCard extends StatelessWidget {
  final double sisa;
  final double income;
  final double expense;
  final double? dailyLimit;
  final bool hideBalance;
  final VoidCallback onToggleHide;

  const _FuturisticBalanceCard({
    required this.sisa,
    required this.income,
    required this.expense,
    required this.dailyLimit,
    required this.hideBalance,
    required this.onToggleHide,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isNegative = sisa < 0;
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);
    final statusColor = isNegative ? expenseColor : incomeColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.surfaceHigh,
                  AppColors.surfaceDark,
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  const Color(0xFFF1F5F9),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark
              ? statusColor.withValues(alpha: 0.35)
              : statusColor.withValues(alpha: 0.25),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Status badge & Eye toggle button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isNegative ? 'Defisit Bulan Ini' : 'Surplus Bersih',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onToggleHide,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 15,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hideBalance ? 'Tampilkan' : 'Sembunyikan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subtitle label
              Text(
                'Sisa Saldo Tersedia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),

              // Hero Balance Number
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  hideBalance ? 'Rp ••••••••' : CurrencyFormatter.format(sisa),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: isNegative
                        ? expenseColor
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
              ),

              // Daily Spending Limit Pill
              if (dailyLimit != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 15,
                        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Batas belanja aman hari ini: ',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        hideBalance ? 'Rp•••' : CurrencyFormatter.format(dailyLimit!),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Integrated Flow Pills (Masuk vs Keluar)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    // Masuk
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: incomeColor.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_downward_rounded, size: 14, color: incomeColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                Text(
                                  hideBalance ? '•••••' : CurrencyFormatter.format(income),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: incomeColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 12),
                    // Keluar
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: expenseColor.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_upward_rounded, size: 14, color: expenseColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Keluar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                Text(
                                  hideBalance ? '•••••' : CurrencyFormatter.format(expense),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: expenseColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trio of modern action buttons for quick logging
class _QuickActionRow extends StatelessWidget {
  final VoidCallback onIncomeTap;
  final VoidCallback onExpenseTap;
  final VoidCallback onSavingTap;

  const _QuickActionRow({
    required this.onIncomeTap,
    required this.onExpenseTap,
    required this.onSavingTap,
  });

  @override
  Widget build(BuildContext context) {
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);
    final isDark = AppColors.isDark(context);
    final savingColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Row(
      children: [
        Expanded(
          child: _QuickPillButton(
            label: 'Uang Masuk',
            icon: Icons.arrow_downward_rounded,
            color: incomeColor,
            onTap: onIncomeTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickPillButton(
            label: 'Uang Keluar',
            icon: Icons.arrow_upward_rounded,
            color: expenseColor,
            onTap: onExpenseTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickPillButton(
            label: 'Tabungan',
            icon: Icons.flag_rounded,
            color: savingColor,
            onTap: onSavingTap,
          ),
        ),
      ],
    );
  }
}

class _QuickPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickPillButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final contentColor = color.computeLuminance() > 0.5
        ? const Color(0xFF0F172A)
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.22 : 0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: isDark ? 0.90 : 0.95),
                  color.withValues(alpha: isDark ? 0.72 : 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: contentColor, size: 20),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: contentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual distribution of where monthly income is going
class _CashFlowDistributionBar extends StatelessWidget {
  final MonthlySummary summary;
  const _CashFlowDistributionBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final total = summary.totalIncome > 0
        ? summary.totalIncome
        : (summary.totalExpense + summary.totalSaving + summary.totalInvestment);

    final expensePercent = total > 0 ? (summary.totalExpense / total).clamp(0.0, 1.0) : 0.0;
    final savingPercent = total > 0 ? (summary.totalSaving / total).clamp(0.0, 1.0) : 0.0;
    final investPercent = total > 0 ? (summary.totalInvestment / total).clamp(0.0, 1.0) : 0.0;

    final expenseColor = AppColors.expense(context);
    final incomeColor = AppColors.income(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final savingColor = isDark ? AppColors.savingDark : AppColors.savingLight;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alokasi Arus Keuangan',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                total > 0 ? 'Basis: ${CurrencyFormatter.format(total)}' : 'Belum ada data',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 10,
              color: isDark ? const Color(0x22FFFFFF) : const Color(0x140F172A),
              child: Row(
                children: [
                  if (expensePercent > 0)
                    Expanded(
                      flex: (expensePercent * 100).toInt().clamp(1, 100),
                      child: Container(color: expenseColor),
                    ),
                  if (savingPercent > 0)
                    Expanded(
                      flex: (savingPercent * 100).toInt().clamp(1, 100),
                      child: Container(color: savingColor),
                    ),
                  if (investPercent > 0)
                    Expanded(
                      flex: (investPercent * 100).toInt().clamp(1, 100),
                      child: Container(color: primaryColor),
                    ),
                  if (summary.sisa > 0 && total > 0)
                    Expanded(
                      flex: ((summary.sisa / total) * 100).toInt().clamp(1, 100),
                      child: Container(color: incomeColor),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legendItem(context, 'Belanja ${(expensePercent * 100).toStringAsFixed(0)}%', expenseColor),
              _legendItem(context, 'Tabungan ${(savingPercent * 100).toStringAsFixed(0)}%', savingColor),
              _legendItem(context, 'Investasi ${(investPercent * 100).toStringAsFixed(0)}%', primaryColor),
              if (summary.sisa > 0 && total > 0)
                _legendItem(context, 'Tersisa ${((summary.sisa / total) * 100).toStringAsFixed(0)}%', incomeColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(BuildContext context, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final MonthlySummary summary;
  final bool hideNumbers;

  const _SummaryGrid({required this.summary, required this.hideNumbers});

  @override
  Widget build(BuildContext context) {
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);
    final isDark = AppColors.isDark(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final savingColor = isDark ? AppColors.savingDark : AppColors.savingLight;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _StatCard(
          label: 'Total Masuk',
          amount: summary.totalIncome,
          color: incomeColor,
          icon: Icons.arrow_downward_rounded,
          hide: hideNumbers,
        ),
        _StatCard(
          label: 'Total Keluar',
          amount: summary.totalExpense,
          color: expenseColor,
          icon: Icons.arrow_upward_rounded,
          hide: hideNumbers,
        ),
        _StatCard(
          label: 'Tabungan',
          amount: summary.totalSaving,
          color: savingColor,
          icon: Icons.savings_rounded,
          hide: hideNumbers,
        ),
        _StatCard(
          label: 'Investasi',
          amount: summary.totalInvestment,
          color: primaryColor,
          icon: Icons.trending_up_rounded,
          hide: hideNumbers,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool hide;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.hide,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 20,
      borderColor: color.withValues(alpha: isDark ? 0.22 : 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              hide ? 'Rp ••••••' : CurrencyFormatter.format(amount),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.3,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<dynamic> categories;
  final bool hideNumbers;
  final VoidCallback onViewAll;

  const _RecentTransactionsSection({
    required this.transactions,
    required this.categories,
    required this.hideNumbers,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaksi Terakhir',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lihat Semua →',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 84,
                      height: 60,
                      child: Lottie.asset(
                        'assets/lottie/cat_mascot.json',
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada transaksi di bulan ini.\nTekan tombol di atas untuk mencatat, meow! 🐾',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 52,
                color: isDark ? const Color(0x1AFFFFFF) : const Color(0x10000000),
              ),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final category = categories
                    .where((c) => c.id == tx.categoryId)
                    .firstOrNull;

                final Color amountColor;
                final String sign;
                switch (tx.type) {
                  case TransactionType.income:
                    amountColor = AppColors.income(context);
                    sign = '+';
                    break;
                  case TransactionType.expense:
                    amountColor = AppColors.expense(context);
                    sign = '-';
                    break;
                  case TransactionType.saving:
                    amountColor = isDark ? AppColors.savingDark : AppColors.savingLight;
                    sign = '-';
                    break;
                  case TransactionType.investment:
                    amountColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
                    sign = '-';
                    break;
                }

                final dateLabel = DateFormat.yMMMd('id_ID').format(tx.date);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  dense: true,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: amountColor.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Icon(
                      CategoryIcons.resolve(category?.icon ?? (tx.type == TransactionType.saving ? 'saving_goal' : 'other')),
                      size: 20,
                      color: amountColor,
                    ),
                  ),
                  title: Text(
                    category?.name ?? tx.type.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    tx.description.isEmpty ? dateLabel : '${tx.description} · $dateLabel',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    hideNumbers ? '••••••' : '$sign${CurrencyFormatter.format(tx.amount)}',
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditTransactionScreen(transaction: tx),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BudgetHealthCard extends StatelessWidget {
  final double budgetUsedPercent;
  final FinancialHealth health;

  const _BudgetHealthCard({
    required this.budgetUsedPercent,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final clamped = budgetUsedPercent.clamp(0, 100).toDouble();
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Health & Budget',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FinancialHealthScreen()),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Detail →',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Budget progress bar
          Row(
            children: [
              Icon(
                Icons.pie_chart_rounded,
                size: 18,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Budget Terpakai',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              Text(
                '${budgetUsedPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: budgetUsedPercent > 100
                      ? AppColors.expense(context)
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0x33FFFFFF) : const Color(0x1F0F172A),
              color: budgetUsedPercent > 100 ? AppColors.expense(context) : primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Mini preview rows
          _MiniHealthRow(label: 'Tabungan', percent: health.savingRate, status: health.savingStatus),
          const SizedBox(height: 8),
          _MiniHealthRow(label: 'Investasi', percent: health.investmentRate, status: health.investmentStatus),
          const SizedBox(height: 8),
          _MiniHealthRow(label: 'Pengeluaran', percent: health.expenseRate, status: health.expenseStatus),
        ],
      ),
    );
  }
}

class _MiniHealthRow extends StatelessWidget {
  final String label;
  final double percent;
  final HealthStatus status;

  const _MiniHealthRow({
    required this.label,
    required this.percent,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Row(
      children: [
        Text(status.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

class _FinancialTrendsChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _FinancialTrendsChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final incomeColor = AppColors.income(context);
    final expenseColor = AppColors.expense(context);

    // Compute weekly data (Week 1 to Week 4)
    final weeks = List.generate(4, (_) => {'income': 0.0, 'expense': 0.0});
    for (final tx in transactions) {
      final day = tx.date.day;
      final weekIndex = ((day - 1) ~/ 7).clamp(0, 3);
      if (tx.type == TransactionType.income) {
        weeks[weekIndex]['income'] = (weeks[weekIndex]['income'] ?? 0) + tx.amount;
      } else if (tx.type == TransactionType.expense) {
        weeks[weekIndex]['expense'] = (weeks[weekIndex]['expense'] ?? 0) + tx.amount;
      }
    }

    final maxVal = weeks.fold<double>(
      100000.0,
      (max, w) => [max, w['income'] ?? 0, w['expense'] ?? 0].reduce((a, b) => a > b ? a : b),
    );

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tren Arus Kas',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Perbandingan mingguan bulan ini',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _LegendDot(color: incomeColor, label: 'Masuk'),
                  const SizedBox(width: 12),
                  _LegendDot(color: expenseColor, label: 'Keluar'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.15,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceHigh,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${isIncome ? "Masuk" : "Keluar"}\n${CurrencyFormatter.format(rod.toY)}',
                        TextStyle(
                          color: isIncome ? incomeColor : expenseColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < 4) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Mg ${idx + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(4, (i) {
                  final inVal = weeks[i]['income'] ?? 0;
                  final outVal = weeks[i]['expense'] ?? 0;
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                        toY: inVal,
                        color: incomeColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                      BarChartRodData(
                        toY: outVal,
                        color: expenseColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

/// Interactive Luxury Animated Cat Companion (Lottie Mascot Hero Card)
class _InteractiveCatHeroCard extends StatefulWidget {
  const _InteractiveCatHeroCard();

  @override
  State<_InteractiveCatHeroCard> createState() => _InteractiveCatHeroCardState();
}

class _InteractiveCatHeroCardState extends State<_InteractiveCatHeroCard>
    with TickerProviderStateMixin {
  late final AnimationController _actionController;
  late final AnimationController _idleBobController;
  int _cheerIndex = 0;

  static const _catCheers = [
    'Purrr... Nyaa~ Kucing Cuan senang dielus! 🐱💖',
    'Meoww! Semangat kumpulin cuan hari ini! ✨🐾',
    'Nyaa~ Pundi-pundi tabungan makin montok! 🐟💰',
    'Horeee! Disiplin finansial nomor satu! 🎉🐱',
    'Purr purr... Saldo aman, hatiku tenang! 🥰🛡️',
    'Meow! Jangan lupa catat jajan kopi hari ini ya! ☕🐾',
    'Kucing Cuan siap siaga jaga brankasmu! 🐾✨',
  ];

  static const _fullTips = [
    '🐾 Catat pengeluaran harian: Pengeluaran kecil yang bocor halus sering menjadi sumber defisit terbesar.',
    '🎯 Amankan 20% penghasilan di awal bulan ke tabungan, jangan menunggu sisa belanja.',
    '🛡️ Siapkan dana darurat minimal 3–6 bulan pengeluaran rutin di rekening terpisah.',
    '✨ Evaluasi langganan berkala (streaming, membership) yang sudah jarang digunakan.',
    '🐱 Pantau sisa budget harian di dashboard agar tetap aman terkendali hingga akhir bulan!',
  ];

  @override
  void initState() {
    super.initState();
    _actionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _idleBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _actionController.dispose();
    _idleBobController.dispose();
    super.dispose();
  }

  void _triggerHappyPet() {
    if (_actionController.isAnimating) return;

    setState(() {
      _cheerIndex = (_cheerIndex + 1) % _catCheers.length;
    });

    HapticFeedback.lightImpact();

    _actionController.forward(from: 0.0);
  }

  void _showTipsModal(BuildContext context) {
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                        height: 50,
                        child: Lottie.asset(
                          'assets/lottie/cat_mascot.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tips Finansial Kucing Cuan 🐾',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              'Pedoman cerdas menjaga stabilitas keuanganmu',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ..._fullTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF34D399).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          tip,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Tutup & Lanjutkan Nabung 🐾',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF131826).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: isDark ? 0.32 : 0.22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34D399).withValues(alpha: isDark ? 0.10 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Greetings, Interactive Speech Bubble & Action Chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mascot Header Row
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF34D399).withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Kucing Cuan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399).withValues(alpha: isDark ? 0.18 : 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Elus aku! 🐱💖',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Interactive Speech Bubble
                    InkWell(
                      onTap: _triggerHappyPet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isDark ? const Color(0xFF1B2236) : const Color(0xFFF1F5F9))
                              .withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          '"${_catCheers[_cheerIndex]}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Bottom info & tips button
                    InkWell(
                      onTap: () => _showTipsModal(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Lihat Tips Keuangan ▾',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Right Column: Interactive Cozy Pet Arena (Large ~118px)
              GestureDetector(
                onTap: _triggerHappyPet,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 118,
                  height: 96,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_actionController, _idleBobController]),
                    builder: (context, _) {
                      double translateY = 0.0;
                      double rotate = 0.0;
                      double scaleX = 1.0;
                      double scaleY = 1.0;
                      double particleProgress = 0.0;
                      bool showParticles = false;

                      if (_actionController.isAnimating) {
                        final t = _actionController.value;
                        showParticles = true;
                        particleProgress = t;

                        if (t < 0.20) {
                          // Phase 1: Anticipation / soft squish down when petted
                          final p = t / 0.20;
                          translateY = p * 4.0;
                          scaleX = 1.0 + p * 0.10;
                          scaleY = 1.0 - p * 0.10;
                        } else if (t < 0.65) {
                          // Phase 2: Joyful cute hop upward with kitten wiggle!
                          final p = (t - 0.20) / 0.45;
                          final hop = math.sin(p * math.pi);
                          translateY = -18.0 * hop;
                          // Wiggle ears and body playfully left & right
                          rotate = math.sin(p * math.pi * 3) * 0.08;
                          scaleX = 1.0 - hop * 0.06;
                          scaleY = 1.0 + hop * 0.08;
                        } else {
                          // Phase 3: Gentle soft landing bounce
                          final p = (t - 0.65) / 0.35;
                          final bounce = math.sin(p * math.pi);
                          translateY = 0.0;
                          rotate = 0.0;
                          scaleX = 1.0 + bounce * 0.10 * (1.0 - p);
                          scaleY = 1.0 - bounce * 0.10 * (1.0 - p);
                        }
                      } else {
                        // Gentle soothing idle breathing bob
                        translateY = math.sin(_idleBobController.value * math.pi) * 2.2;
                      }

                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Cozy Ground Shadow underneath the cat
                          Positioned(
                            bottom: 8,
                            child: Transform.scale(
                              scaleX: 1.0 - (translateY < 0 ? (-translateY / 18.0) * 0.35 : 0.0),
                              scaleY: 0.7,
                              child: Container(
                                width: 64,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(
                                    alpha: 0.28 - (translateY < 0 ? (-translateY / 18.0) * 0.15 : 0.0),
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),

                          // Floating Love & Sparkle Particles on Pet
                          if (showParticles) ...[
                            // Left heart floating up & left
                            Positioned(
                              top: 14 - (particleProgress * 32),
                              left: 20 - (particleProgress * 12),
                              child: Opacity(
                                opacity: (1.0 - particleProgress).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.6 + particleProgress * 0.6,
                                  child: const Text('💖', style: TextStyle(fontSize: 14)),
                                ),
                              ),
                            ),
                            // Center star sparkle floating straight up higher
                            Positioned(
                              top: 6 - (particleProgress * 38),
                              left: 48,
                              child: Opacity(
                                opacity: (1.0 - particleProgress).clamp(0.0, 1.0),
                                child: Transform.rotate(
                                  angle: particleProgress * math.pi,
                                  child: Transform.scale(
                                    scale: 0.7 + particleProgress * 0.5,
                                    child: const Text('✨', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ),
                            ),
                            // Right paw floating up & right
                            Positioned(
                              top: 16 - (particleProgress * 28),
                              right: 18 - (particleProgress * 10),
                              child: Opacity(
                                opacity: (1.0 - particleProgress).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.6 + particleProgress * 0.5,
                                  child: const Text('🐾', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ),
                          ],

                          // The Cat Mascot (Large 112px x 80px, aspect 1.4:1)
                          Transform.translate(
                            offset: Offset(0.0, translateY),
                            child: Transform.rotate(
                              angle: rotate,
                              child: Transform.scale(
                                scaleX: scaleX,
                                scaleY: scaleY,
                                child: SizedBox(
                                  width: 112,
                                  height: 80,
                                  child: Lottie.asset(
                                    'assets/lottie/cat_mascot.json',
                                    fit: BoxFit.contain,
                                    repeat: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardChatButton extends ConsumerWidget {
  const _DashboardChatButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final unreadCount = ref.watch(totalUnreadChatCountProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceHighDark.withValues(alpha: 0.75)
                : AppColors.surfaceHighLight.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.incomeDark : AppColors.incomeLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppColors.incomeDark : AppColors.incomeLight)
                              .withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


