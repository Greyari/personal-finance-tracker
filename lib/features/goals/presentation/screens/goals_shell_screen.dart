import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../investments/presentation/screens/investment_list_screen.dart';
import 'saving_goal_list_screen.dart';

/// Hosts both Section 11 (Tabungan) and Section 12 (Investasi) under the
/// single "Goals" bottom-nav slot, styled with glassmorphism tabs.
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
    final isDark = AppColors.isDark(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Target & Investasi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x331E293B) : const Color(0x24FFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              labelColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Target Tabungan'),
                Tab(text: 'Portofolio Investasi'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SavingGoalListScreen(),
          InvestmentListScreen(),
        ],
      ),
    );
  }
}
