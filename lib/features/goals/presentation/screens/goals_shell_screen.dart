import 'package:flutter/material.dart';

import '../../../investments/presentation/screens/investment_list_screen.dart';
import 'saving_goal_list_screen.dart';

/// Hosts both Section 11 (Tabungan) and Section 12 (Investasi) under the
/// single "Goals" bottom-nav slot, since the spec's nav bar (Section 20)
/// has one Goals entry but two distinct features belong there.
class GoalsShellScreen extends StatefulWidget {
  const GoalsShellScreen({super.key});

  @override
  State<GoalsShellScreen> createState() => _GoalsShellScreenState();
}

class _GoalsShellScreenState extends State<GoalsShellScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Tabungan'), Tab(text: 'Investasi')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [SavingGoalListScreen(), InvestmentListScreen()],
      ),
    );
  }
}
