import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';

/// Cover image for saving goals. Accepts an asset path (`assets/...`),
/// a network URL (`http...`) or a local file path. Shows a shimmer while
/// loading and falls back to an elegant gradient placeholder when the
/// photo is missing or fails to load.
class GoalCoverImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;

  const GoalCoverImage({super.key, this.path, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final value = path;
    if (value == null || value.isEmpty) return const _CoverPlaceholder();

    final Widget image;
    if (value.startsWith('assets/')) {
      image = Image.asset(value, fit: fit, errorBuilder: _error);
    } else if (value.startsWith('http')) {
      image = Image.network(
        value,
        fit: fit,
        errorBuilder: _error,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const _CoverShimmer(),
      );
    } else if (kIsWeb) {
      return const _CoverPlaceholder();
    } else {
      image = Image.file(
        File(value),
        fit: fit,
        errorBuilder: _error,
        frameBuilder: (context, child, frame, wasSync) {
          if (wasSync || frame != null) return child;
          return const _CoverShimmer();
        },
      );
    }
    return image;
  }

  Widget _error(BuildContext context, Object error, StackTrace? stack) =>
      const _CoverPlaceholder();
}

class _CoverShimmer extends StatelessWidget {
  const _CoverShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark,
      highlightColor: AppColors.surfaceHigh,
      child: Container(color: AppColors.surfaceDark),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232D42), AppColors.surfaceDark, Color(0xFF1E293B)],
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            Icons.photo_outlined,
            color: AppColors.primaryDark.withValues(alpha: 0.35),
            size: 28,
          ),
        ),
      ),
    );
  }
}
