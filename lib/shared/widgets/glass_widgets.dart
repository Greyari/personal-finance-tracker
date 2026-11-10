import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Background with rich ambient glowing color blobs and subtle
/// topographic contour mesh that provides stunning optical depth
/// and refraction for Glassmorphism.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Stack(
      children: [
        // Base luxury gradient background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF080B11),
                        Color(0xFF0E131F),
                        Color(0xFF0A0D14),
                      ]
                    : const [
                        Color(0xFFF8FAFC),
                        Color(0xFFF1F5F9),
                        Color(0xFFE9EEF5),
                      ],
              ),
            ),
          ),
        ),

        // Radiant Orb 1: Top-Left Emerald Aura (Uang & Pertumbuhan)
        Positioned(
          top: -90,
          left: -70,
          width: 380,
          height: 380,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF10B981) : const Color(0xFF059669))
                      .withValues(alpha: isDark ? 0.20 : 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Radiant Orb 2: Top-Right Monochromatic Luminous Highlight
        Positioned(
          top: 60,
          right: -80,
          width: 360,
          height: 360,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? Colors.white : const Color(0xFF0F172A))
                      .withValues(alpha: isDark ? 0.12 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Radiant Orb 3: Mid-Left Subtle Rose Warmth
        Positioned(
          top: 360,
          left: -100,
          width: 360,
          height: 360,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFFF43F5E) : const Color(0xFFDC2626))
                      .withValues(alpha: isDark ? 0.12 : 0.09),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Radiant Orb 4: Bottom-Right Cool Indigo Depth
        Positioned(
          bottom: -70,
          right: -40,
          width: 400,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                      .withValues(alpha: isDark ? 0.10 : 0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Subtle Topographic Geometric Mesh (Shimmers through blurred glass)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BackgroundMeshPainter(isDark: isDark),
            ),
          ),
        ),

        // Foreground content
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Custom painter that draws faint, luxury topographic contour waves
/// so that frosted glass BackdropFilters produce optical refraction.
class _BackgroundMeshPainter extends CustomPainter {
  final bool isDark;

  const _BackgroundMeshPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.035)
          : const Color(0xFF0F172A).withValues(alpha: 0.030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final accentPaint = Paint()
      ..color = (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
          .withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Curved contour wave 1 (upper section)
    final path1 = Path();
    path1.moveTo(-40, size.height * 0.16);
    path1.cubicTo(
      size.width * 0.35,
      size.height * 0.10,
      size.width * 0.65,
      size.height * 0.26,
      size.width + 50,
      size.height * 0.20,
    );
    canvas.drawPath(path1, linePaint);

    // Curved contour wave 2 (mid section)
    final path2 = Path();
    path2.moveTo(-50, size.height * 0.38);
    path2.cubicTo(
      size.width * 0.30,
      size.height * 0.46,
      size.width * 0.70,
      size.height * 0.32,
      size.width + 60,
      size.height * 0.44,
    );
    canvas.drawPath(path2, accentPaint);

    // Curved contour wave 3 (lower section)
    final path3 = Path();
    path3.moveTo(-40, size.height * 0.65);
    path3.cubicTo(
      size.width * 0.40,
      size.height * 0.58,
      size.width * 0.60,
      size.height * 0.74,
      size.width + 50,
      size.height * 0.68,
    );
    canvas.drawPath(path3, linePaint);

    // Concentric geometric rings (Upper Right)
    final center1 = Offset(size.width * 0.88, size.height * 0.16);
    canvas.drawCircle(center1, 110, linePaint);
    canvas.drawCircle(center1, 170, accentPaint);

    // Concentric geometric rings (Lower Left)
    final center2 = Offset(size.width * 0.10, size.height * 0.78);
    canvas.drawCircle(center2, 130, linePaint);
    canvas.drawCircle(center2, 200, linePaint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundMeshPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// A Scaffold wrapper that automatically embeds the GlassBackground
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

/// Reusable Glass Card with blurred glass effect, subtle border,
/// and soft diffused shadow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? customFill;
  final Color? customBorder;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = AppRadius.card,
    this.onTap,
    this.customFill,
    this.customBorder,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final fill = customFill ?? (isDark ? AppColors.glassCardDark : AppColors.glassCardLight);
    final border = customBorder ?? (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);

    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: customFill == null && isDark ? null : fill,
            gradient: customFill == null && isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x1FFFFFFF), Color(0x08FFFFFF)],
                  )
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x33000000) : const Color(0x0C0F172A),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      if (onTap != null) {
        return Padding(
          padding: margin!,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: onTap,
              child: cardContent,
            ),
          ),
        );
      }
      return Padding(padding: margin!, child: cardContent);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Lightweight Glass Container (avoids per-item BackdropFilter on long lists)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? fillColor;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final fill = fillColor ?? (isDark ? AppColors.glassFillDark : AppColors.glassFillLight);
    final border = borderColor ?? (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);

    final containerDecoration = BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: border, width: 1.1),
      boxShadow: [
        BoxShadow(
          color: isDark ? const Color(0x20000000) : const Color(0x080F172A),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );

    Widget result;
    if (onTap != null) {
      result = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Ink(
          decoration: containerDecoration,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    } else {
      result = Container(
        padding: padding,
        decoration: containerDecoration,
        child: child,
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: result);
    }
    return result;
  }
}

/// Frosted Glass Button with subtle gradient and pressed state
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final double height;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primaryColor = backgroundColor ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final effectiveContrastColor = primaryColor.computeLuminance() > 0.5
        ? const Color(0xFF0F172A)
        : Colors.white;
    final textColor = foregroundColor ?? (isOutlined ? primaryColor : effectiveContrastColor);

    if (isOutlined) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: (isDark ? AppColors.glassFillDark : Colors.white.withValues(alpha: 0.6)),
          border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: primaryColor),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 19, color: textColor),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: textColor),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 19, color: textColor),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
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

/// Active top notification entry tracker so multiple triggers replace cleanly
OverlayEntry? _activeTopNotification;

/// Shows a floating notification at the TOP of the screen (below status bar),
/// styled with modern glass theme and smooth slide-down animation.
void showGlassSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  IconData? icon,
  Duration duration = const Duration(milliseconds: 2800),
}) {
  // Hide current snackbar if any is active from standard ScaffoldMessenger
  try {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  } catch (_) {}

  // Dismiss previous top notification if still visible
  if (_activeTopNotification != null) {
    try {
      _activeTopNotification!.remove();
    } catch (_) {}
    _activeTopNotification = null;
  }

  final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);

  OverlayEntry? entry;
  entry = OverlayEntry(
    builder: (ctx) => _TopNotificationWidget(
      message: message,
      isError: isError,
      icon: icon,
      duration: duration,
      onDismiss: () {
        if (entry != null && entry.mounted) {
          entry.remove();
          if (_activeTopNotification == entry) {
            _activeTopNotification = null;
          }
        }
      },
    ),
  );

  _activeTopNotification = entry;
  overlay.insert(entry);
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.isError,
    this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = widget.isError
        ? AppColors.expense(context)
        : (isDark ? AppColors.primaryDark : AppColors.primaryLight);

    return SafeArea(
      top: true,
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _dismiss,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                    _dismiss();
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.6),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon ??
                                (widget.isError
                                    ? Icons.error_outline_rounded
                                    : Icons.check_circle_outline_rounded),
                            color: accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to show a modern, high-contrast confirmation dialog
/// that renders solidly and reliably across all Android devices and GPUs.
Future<bool?> showGlassConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
  String cancelLabel = 'Batal',
  bool isDestructive = true,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      final isDark = AppColors.isDark(ctx);
      final destColor = AppColors.expense(ctx);
      final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
      final actionColor = isDestructive ? destColor : primaryColor;
      final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
      final subTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
      final borderColor = isDark ? const Color(0x3394A3B8) : const Color(0x1F0F172A);

      return AlertDialog(
        backgroundColor: bgColor,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? (isDestructive ? Icons.delete_outline_rounded : Icons.info_outline_rounded),
                color: actionColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: subTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: subTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: actionColor.computeLuminance() > 0.5
                  ? const Color(0xFF0F172A)
                  : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      );
    },
  );
}

/// Frosted Glass Navigation Bar item descriptor
class GlassNavItem {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;

  const GlassNavItem({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
  });
}

/// Floating frosted glass bottom navigation bar with fluid active indicator
class GlassBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<GlassNavItem> items;

  const GlassBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final activeColor = isDark ? Colors.white : AppColors.primaryLight;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.60)
        : AppColors.textSecondaryLight;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.45) : const Color(0x180F172A),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0.06),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.60),
                          Colors.white.withValues(alpha: 0.35),
                        ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.30 : 0.75),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (idx) {
                  final isSelected = selectedIndex == idx;
                  final item = items[idx];

                  return InkWell(
                    onTap: () => onItemSelected(idx),
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 14 : 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.80))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        border: isSelected
                            ? Border.all(
                                color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.9),
                                width: 1,
                              )
                            : null,
                        boxShadow: (isSelected && !isDark)
                            ? [
                                const BoxShadow(
                                  color: Color(0x10000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.unselectedIcon,
                            color: isSelected ? activeColor : inactiveColor,
                            size: 21,
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: activeColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating circular action button with glass glow, positioned with safe clearance
/// above the floating bottom navigation bar so it is never covered.
class GlassCircularFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;
  final IconData icon;
  final Object? heroTag;
  final Color? color;
  final double bottomMargin;

  const GlassCircularFab({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.icon = Icons.add_rounded,
    this.heroTag,
    this.color,
    this.bottomMargin = 78,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primaryColor = color ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight);
    final iconColor = primaryColor.computeLuminance() > 0.5
        ? const Color(0xFF0F172A)
        : Colors.white;

    final fab = Container(
      margin: EdgeInsets.only(bottom: bottomMargin, right: 6),
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.45 : 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip ?? 'Tambah',
            child: Center(
              child: Icon(icon, color: iconColor, size: 30),
            ),
          ),
        ),
      ),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: fab);
    }
    return fab;
  }
}

/// Reusable Glass Sliver Pull-To-Refresh control with buttery-smooth
/// physics and a sleek frosted glass pill indicator.
///
/// Features:
/// - Locks in "Lepas untuk memperbarui" while holding down past trigger threshold
/// - Never prematurely cancels or resets back to "Tarik ke bawah" while finger is touching
/// - Only triggers refresh completion when the user actually releases their touch
/// - Smooth animated transitions with high-contrast text and adaptive icon
class GlassSliverRefreshControl extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  const GlassSliverRefreshControl({
    super.key,
    required this.onRefresh,
    this.refreshTriggerPullDistance = 88.0,
    this.refreshIndicatorExtent = 52.0,
  });

  @override
  State<GlassSliverRefreshControl> createState() => _GlassSliverRefreshControlState();
}

class _GlassSliverRefreshControlState extends State<GlassSliverRefreshControl> {
  Completer<void>? _refreshCompleter;
  bool _hasReleased = false;

  Future<void> _handleRefresh() async {
    final completer = Completer<void>();
    _refreshCompleter = completer;
    _hasReleased = false;

    // Run the actual user refresh in background
    final Future<void> refreshFuture = widget.onRefresh();

    unawaited(() async {
      try {
        await refreshFuture;
      } catch (_) {}

      // Wait until the user has actually released their finger
      // (which transitions CupertinoSliverRefreshControl into RefreshIndicatorMode.refresh)
      final timeoutWatch = Stopwatch()..start();
      while (!_hasReleased && mounted && _refreshCompleter == completer) {
        if (timeoutWatch.elapsedMilliseconds > 12000) break; // 12s safety timeout
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }

      // Smooth visual grace period so the spinner is satisfying and legible
      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (mounted && !completer.isCompleted) {
        completer.complete();
      }
    }());

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final activeColor = isDark ? Colors.white : AppColors.primaryLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return CupertinoSliverRefreshControl(
      onRefresh: _handleRefresh,
      refreshTriggerPullDistance: widget.refreshTriggerPullDistance,
      refreshIndicatorExtent: widget.refreshIndicatorExtent,
      builder: (
        BuildContext context,
        RefreshIndicatorMode refreshState,
        double pulledExtent,
        double refreshTriggerPullDistance,
        double refreshIndicatorExtent,
      ) {
        if (refreshState == RefreshIndicatorMode.refresh) {
          _hasReleased = true;
        } else if (refreshState == RefreshIndicatorMode.inactive && pulledExtent <= 0) {
          if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
            _refreshCompleter!.complete();
          }
        }

        if (pulledExtent <= 6) return const SizedBox.shrink();

        final bool isRefreshing = refreshState == RefreshIndicatorMode.refresh;
        final bool isArmed = refreshState == RefreshIndicatorMode.armed;
        final double progress = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.30)
                      : const Color(0x0E0F172A),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isRefreshing
                    ? CupertinoActivityIndicator(radius: 9, color: activeColor)
                    : CupertinoActivityIndicator.partiallyRevealed(
                        radius: 9,
                        color: activeColor,
                        progress: progress,
                      ),
                const SizedBox(width: 8),
                Text(
                  isRefreshing
                      ? 'Memperbarui data...'
                      : (isArmed ? 'Lepas untuk memperbarui' : 'Tarik ke bawah'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
