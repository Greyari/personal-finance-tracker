import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../budgets/presentation/screens/budget_list_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../goals/presentation/screens/goals_shell_screen.dart';
import '../../../recurring/presentation/providers/recurring_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../transactions/presentation/screens/transaction_list_screen.dart';

/// Bottom navigation shell per the UI spec: Home, Transactions, Budget,
/// Goals, Settings. All five tabs are now real (Phase 6) — Goals hosts
/// both Saving Goals and Investments as sub-tabs (see GoalsShellScreen).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    TransactionListScreen(),
    BudgetListScreen(),
    GoalsShellScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Silently checks once per app session whether this month's active
    // recurring transactions (e.g. Internet, Gereja 10%) have already
    // been generated, and creates any that are missing. See
    // recurringGenerationProvider for why this is a client-side check
    // rather than a scheduled Cloud Function.
    ref.watch(recurringGenerationProvider);

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
