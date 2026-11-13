import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Human-crafted minimalist luxury stationery icon for Notes.
/// Designed with Apple / Linear aesthetic: a sleek rounded memo note sheet
/// with an elegant dog-ear folded corner, clean content lines, and a subtle glowing accent.
class CustomGlassPinIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? accentColor;

  const CustomGlassPinIcon({
    super.key,
    this.size = 20,
    this.color,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
    final primary = color ?? defaultColor;
    final accent = accentColor ?? const Color(0xFF34D399); // Emerald accent

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LuxuryNotePainter(
          primaryColor: primary,
          accentColor: accent,
        ),
      ),
    );
  }
}

class _LuxuryNotePainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  const _LuxuryNotePainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Proportions for a luxury rounded memo sheet
    final left = w * 0.16;
    final top = h * 0.12;
    final right = w * 0.84;
    final bottom = h * 0.88;
    final cornerRadius = w * 0.12;
    final foldSize = w * 0.24;

    // Body Path with folded top-right corner
    final bodyPath = Path()
      ..moveTo(left + cornerRadius, top)
      ..lineTo(right - foldSize, top)
      ..lineTo(right, top + foldSize)
      ..lineTo(right, bottom - cornerRadius)
      ..arcToPoint(
        Offset(right - cornerRadius, bottom),
        radius: Radius.circular(cornerRadius),
      )
      ..lineTo(left + cornerRadius, bottom)
      ..arcToPoint(
        Offset(left, bottom - cornerRadius),
        radius: Radius.circular(cornerRadius),
      )
      ..lineTo(left, top + cornerRadius)
      ..arcToPoint(
        Offset(left + cornerRadius, top),
        radius: Radius.circular(cornerRadius),
      )
      ..close();

    // Subtle translucent glass fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: 0.20),
          primaryColor.withValues(alpha: 0.06),
        ],
      ).createShader(Rect.fromLTWH(left, top, right - left, bottom - top))
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, fillPaint);

    // Clean outer border stroke
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = math.max(1.4, w * 0.08)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bodyPath, strokePaint);

    // Top-Right Dog-Ear Fold Flap
    final foldPath = Path()
      ..moveTo(right - foldSize, top)
      ..lineTo(right - foldSize, top + foldSize)
      ..lineTo(right, top + foldSize);
    canvas.drawPath(foldPath, strokePaint);

    // Fold inner subtle fill
    final foldFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final foldPoly = Path()
      ..moveTo(right - foldSize, top)
      ..lineTo(right - foldSize, top + foldSize)
      ..lineTo(right, top + foldSize)
      ..close();
    canvas.drawPath(foldPoly, foldFill);

    // Clean Minimalist Note Content Lines (embossed stationery lines)
    final linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.75)
      ..strokeWidth = math.max(1.3, w * 0.075)
      ..strokeCap = StrokeCap.round;

    // Line 1 (Upper short header line)
    canvas.drawLine(
      Offset(w * 0.30, h * 0.40),
      Offset(w * 0.54, h * 0.40),
      linePaint,
    );

    // Line 2 (Middle full line)
    canvas.drawLine(
      Offset(w * 0.30, h * 0.55),
      Offset(w * 0.70, h * 0.55),
      linePaint,
    );

    // Line 3 (Lower medium line)
    canvas.drawLine(
      Offset(w * 0.30, h * 0.70),
      Offset(w * 0.60, h * 0.70),
      linePaint,
    );

    // Accent Emerald Jewel Bookmark / Seal Dot at bottom-right
    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.70, h * 0.70), math.max(1.8, w * 0.07), dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LuxuryNotePainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor;
}

/// Natural luxury notification bell icon with Apple-style soft curves and soundwaves.
class CustomLuxuryBellIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? accentColor;
  final bool hasRipples;

  const CustomLuxuryBellIcon({
    super.key,
    this.size = 20,
    this.color,
    this.accentColor,
    this.hasRipples = true,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
    final primary = color ?? defaultColor;
    final accent = accentColor ?? const Color(0xFF34D399);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LuxuryBellPainter(
          primaryColor: primary,
          accentColor: accent,
          hasRipples: hasRipples,
        ),
      ),
    );
  }
}

class _LuxuryBellPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final bool hasRipples;

  const _LuxuryBellPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.hasRipples,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top loop
    final loopPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = w * 0.08
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.18), radius: w * 0.08),
      math.pi,
      math.pi,
      false,
      loopPaint,
    );

    // Bell dome path (smooth Apple-style bell curve)
    final bellPath = Path();
    bellPath.moveTo(w * 0.38, h * 0.22);
    bellPath.cubicTo(
      w * 0.38,
      h * 0.40,
      w * 0.22,
      h * 0.58,
      w * 0.20,
      h * 0.70,
    );
    bellPath.quadraticBezierTo(w * 0.5, h * 0.74, w * 0.80, h * 0.70);
    bellPath.cubicTo(
      w * 0.78,
      h * 0.58,
      w * 0.62,
      h * 0.40,
      w * 0.62,
      h * 0.22,
    );
    bellPath.close();

    // Translucent glass fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.25),
          primaryColor.withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(bellPath, fillPaint);

    // Bell stroke
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bellPath, strokePaint);

    // Rim bar
    final rimPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.18, h * 0.71),
      Offset(w * 0.82, h * 0.71),
      rimPaint,
    );

    // Clapper pendulum
    final clapperPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.82), w * 0.09, clapperPaint);

    // Subtle acoustic ripple if active
    if (hasRipples) {
      final ripplePaint = Paint()
        ..color = accentColor.withValues(alpha: 0.6)
        ..strokeWidth = w * 0.065
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.46), radius: w * 0.40),
        math.pi * 0.90,
        math.pi * 0.32,
        false,
        ripplePaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.46), radius: w * 0.40),
        -math.pi * 0.22,
        math.pi * 0.32,
        false,
        ripplePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LuxuryBellPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.hasRipples != hasRipples;
}

/// Natural luxury circular repeat icon for "Setiap Hari".
class CustomDailyRepeatIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const CustomDailyRepeatIcon({
    super.key,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF34D399)
        : const Color(0xFF059669);
    final paintColor = color ?? defaultColor;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DailyRepeatPainter(color: paintColor),
      ),
    );
  }
}

class _DailyRepeatPainter extends CustomPainter {
  final Color color;

  const _DailyRepeatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final radius = w * 0.35;

    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.85,
      math.pi * 0.70,
      false,
      arcPaint,
    );

    // Arrowhead top right
    final arrow1 = Path()
      ..moveTo(w * 0.74, h * 0.16)
      ..lineTo(w * 0.88, h * 0.22)
      ..lineTo(w * 0.76, h * 0.36);
    canvas.drawPath(arrow1, arcPaint..strokeJoin = StrokeJoin.round);

    // Bottom arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.15,
      math.pi * 0.70,
      false,
      arcPaint,
    );

    // Arrowhead bottom left
    final arrow2 = Path()
      ..moveTo(w * 0.26, h * 0.84)
      ..lineTo(w * 0.12, h * 0.78)
      ..lineTo(w * 0.24, h * 0.64);
    canvas.drawPath(arrow2, arcPaint);

    // Center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.08, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _DailyRepeatPainter oldDelegate) =>
      oldDelegate.color != color;
}
