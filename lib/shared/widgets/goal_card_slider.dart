import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/goals/data/models/saving_goal_model.dart';
import 'goal_cover_image.dart';

/// Horizontal card slider for savings targets & budget cards.
/// Designed after Visual Reference 3 (`referensi visual/3.webp`).
/// Supports photo background with subtle dark gradient overlay.
class GoalCardSlider extends StatefulWidget {
  final List<SavingGoalModel> goals;
  final ValueChanged<SavingGoalModel>? onGoalTap;
  final VoidCallback? onAddGoalTap;
  final double viewportFraction;

  const GoalCardSlider({
    super.key,
    required this.goals,
    this.onGoalTap,
    this.onAddGoalTap,
    this.viewportFraction = 0.88,
  });

  @override
  State<GoalCardSlider> createState() => _GoalCardSliderState();
}

class _GoalCardSliderState extends State<GoalCardSlider> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.goals.isEmpty) {
      return _buildEmptyState(context);
    }

    final totalCount = widget.goals.length + (widget.onAddGoalTap != null ? 1 : 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalCount,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              if (index < widget.goals.length) {
                final goal = widget.goals[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _GoalCardItem(
                    goal: goal,
                    onTap: () => widget.onGoalTap?.call(goal),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _AddGoalCardItem(onTap: widget.onAddGoalTap!),
                );
              }
            },
          ),
        ),
        if (totalCount > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          _buildPageIndicator(context, totalCount),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      height: 180,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColors.glassBorderLight,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_outlined,
                color: primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Belum ada target tabungan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mulai sisihkan uang untuk impianmu',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            if (widget.onAddGoalTap != null) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: widget.onAddGoalTap,
                icon: Icon(Icons.add, size: 16, color: primaryColor),
                label: Text(
                  'Tambah Target',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context, int count) {
    final isDark = AppColors.isDark(context);
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor = (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight).withValues(alpha: 0.3);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isSelected = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: isSelected ? 20 : 6,
          decoration: BoxDecoration(
            color: isSelected ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _GoalCardItem extends StatelessWidget {
  final SavingGoalModel goal;
  final VoidCallback onTap;

  const _GoalCardItem({
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).toInt();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: goal.isAchieved
                  ? AppColors.primaryDark.withValues(alpha: 0.6)
                  : AppColors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Cover photo if applicable
              Positioned.fill(
                child: GoalCoverImage(path: goal.coverImagePath),
              ),

              // Subtle dark gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.90),
                      ],
                    ),
                  ),
                ),
              ),

              // Decorative glow blob
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryDark.withValues(alpha: 0.1),
                  ),
                ),
              ),

              // Card content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header row: Icon, Name, and Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            goal.isAchieved
                                ? Icons.check_circle_rounded
                                : Icons.flag_rounded,
                            color: AppColors.primaryDark,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            goal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: goal.isAchieved
                                ? AppColors.primaryDark
                                : AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.primaryDark.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$percent%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: goal.isAchieved
                                  ? AppColors.onAccent
                                  : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Amount display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terkumpul',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              CurrencyFormatter.format(goal.currentAmount),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '/ ${CurrencyFormatter.format(goal.targetAmount)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 6,
                            backgroundColor:
                                AppColors.textSecondaryDark.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }
}

class _AddGoalCardItem extends StatelessWidget {
  final VoidCallback onTap;

  const _AddGoalCardItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isDark ? AppColors.cardBorder : AppColors.glassBorderLight,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tambah Target Baru',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
