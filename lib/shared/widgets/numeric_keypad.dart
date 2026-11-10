import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// Custom in-app numeric keypad for transaction/goal/budget money input.
/// Designed after Visual Reference 2 (`referensi visual/2.webp`).
/// Fully responsive to both Dark Mode and Light Mode with frosted glass aesthetics.
///
/// Layout:
///   1   2   3
///   4   5   6
///   7   8   9
///  000  0   ⌫
class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onLongDeletePressed;

  const NumericKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onDeletePressed,
    this.onLongDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: AppSpacing.xs),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: AppSpacing.xs),
        _buildBottomRow(context),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _KeypadButton(
              label: key,
              onTap: () {
                HapticFeedback.lightImpact();
                onKeyPressed(key);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _KeypadButton(
              label: '000',
              fontSize: 20,
              onTap: () {
                HapticFeedback.lightImpact();
                onKeyPressed('000');
              },
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _KeypadButton(
              label: '0',
              onTap: () {
                HapticFeedback.lightImpact();
                onKeyPressed('0');
              },
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _KeypadIconButton(
              icon: Icons.backspace_outlined,
              onTap: () {
                HapticFeedback.lightImpact();
                onDeletePressed();
              },
              onLongPress: onLongDeletePressed != null
                  ? () {
                      HapticFeedback.mediumImpact();
                      onLongDeletePressed!();
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;

  const _KeypadButton({
    required this.label,
    required this.onTap,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bgColor = isDark
        ? AppColors.surfaceHigh.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.75);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0x180F172A);
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.button),
            splashColor: AppColors.primary.withValues(alpha: 0.15),
            highlightColor: AppColors.primary.withValues(alpha: 0.08),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        const BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeypadIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _KeypadIconButton({
    required this.icon,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bgColor = isDark
        ? AppColors.surfaceHigh.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.75);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0x180F172A);
    final iconColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(AppRadius.button),
            splashColor: AppColors.expense(context).withValues(alpha: 0.2),
            highlightColor: AppColors.expense(context).withValues(alpha: 0.1),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        const BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
