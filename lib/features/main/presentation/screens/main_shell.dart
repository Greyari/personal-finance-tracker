import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../budgets/presentation/screens/budget_list_screen.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../goals/presentation/screens/goals_shell_screen.dart';
import '../../../recurring/presentation/providers/recurring_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../transactions/presentation/screens/transaction_list_screen.dart';
import '../../../../shared/widgets/glass_widgets.dart';

/// State provider for bottom navigation index, allowing other screens
/// (like Dashboard quick actions) to programmatically switch tabs.
final mainNavIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    DashboardScreen(),
    TransactionListScreen(),
    BudgetListScreen(),
    GoalsShellScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Silently checks once per app session whether this month's active
    // recurring transactions have already been generated.
    ref.watch(recurringGenerationProvider);
    ref.watch(chatNotificationWatcherProvider);
    final index = ref.watch(mainNavIndexProvider);

    return GlassScaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: GlassBottomNav(
        selectedIndex: index,
        onItemSelected: (newIndex) =>
            ref.read(mainNavIndexProvider.notifier).state = newIndex,
        items: const [
          GlassNavItem(
            selectedIcon: Icons.home_rounded,
            unselectedIcon: Icons.home_outlined,
            label: 'Home',
          ),
          GlassNavItem(
            selectedIcon: Icons.swap_horiz_rounded,
            unselectedIcon: Icons.swap_horiz_outlined,
            label: 'Transaksi',
          ),
          GlassNavItem(
            selectedIcon: Icons.pie_chart_rounded,
            unselectedIcon: Icons.pie_chart_outline_rounded,
            label: 'Budget',
          ),
          GlassNavItem(
            selectedIcon: Icons.flag_rounded,
            unselectedIcon: Icons.flag_outlined,
            label: 'Goals',
          ),
          GlassNavItem(
            selectedIcon: Icons.settings_rounded,
            unselectedIcon: Icons.settings_outlined,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
