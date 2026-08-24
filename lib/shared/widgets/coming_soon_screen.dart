import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Generic placeholder for bottom-nav tabs whose feature hasn't been
/// built yet in the phased plan (Budget: Phase 3, Goals: Phase 4).
/// Swap this out for the real screen once that phase lands — nothing
/// else references this widget by name.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.title,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('$title akan segera hadir',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
