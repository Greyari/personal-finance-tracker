import 'package:flutter/material.dart';

/// Primary button with a built-in loading spinner, so every screen that
/// triggers an async action (sign in, save transaction, etc.) shows a
/// consistent loading state and can't be double-tapped while loading.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child:
                  CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(label),
    );
  }
}
