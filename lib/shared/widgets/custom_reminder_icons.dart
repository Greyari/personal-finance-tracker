import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Unique handcrafted vector icon for the Floating Pin Note Button.
/// Features a luxury faceted crystal glass head, metallic needle, and glowing core.
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
        painter: _GlassPinPainter(
          primaryColor: primary,
          accentColor: accent,
        ),
      ),
    );
  }
}

class _GlassPinPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  const _GlassPinPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Needle shaft (slanted bottom-left to center-right)
    final needlePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.65)
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;

    final needlePath = Path()
      ..moveTo(w * 0.22, h * 0.88)
      ..lineTo(w * 0.48, h * 0.54);
    canvas.drawPath(needlePath, needlePathPaint(needlePaint, w));

    // Faceted Crystal Pin Head
    final center = Offset(w * 0.60, h * 0.38);
    final radius = w * 0.28;

    // Outer crystal rim (faceted diamond / octagonal shield)
    final headPath = Path();
    const sides = 6;
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - (math.pi / 6);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        headPath.moveTo(x, y);
      } else {
        headPath.lineTo(x, y);
      }
    }
    headPath.close();

    // Translucent glass fill
    final glassFillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.10),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(headPath, glassFillPaint);

    // Crystal outer border
    final glassBorderPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.85)
      ..strokeWidth = w * 0.065
      ..style = PaintingStyle.stroke;
    canvas.drawPath(headPath, glassBorderPaint);

    // Glowing Emerald Core Jewel
    final jewelPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.42, jewelPaint);

    // Specular highlight gleam on the core
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.12, center.dy - radius * 0.12),
      radius * 0.14,
      highlightPaint,
    );
  }

  Paint needlePathPaint(Paint base, double width) {
    return base..strokeWidth = width * 0.085;
  }

  @override
  bool shouldRepaint(covariant _GlassPinPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor;
}

/// Unique handcrafted vector icon for Reminder Notification Bell.
/// Features sculpted acoustic arches, glowing clapper, and soundwave ripples.
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

    // Top hanger loop
    final loopPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.8)
      ..strokeWidth = w * 0.08
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.20), radius: w * 0.10),
      math.pi,
      math.pi,
      false,
      loopPaint,
    );

    // Bell Body Path
    final bellPath = Path();
    bellPath.moveTo(w * 0.38, h * 0.22);
    // Left curve down to flared lip
    bellPath.cubicTo(
      w * 0.38,
      h * 0.42,
      w * 0.20,
      h * 0.62,
      w * 0.18,
      h * 0.72,
    );
    // Bottom lip curve
    bellPath.quadraticBezierTo(w * 0.5, h * 0.76, w * 0.82, h * 0.72);
    // Right curve up
    bellPath.cubicTo(
      w * 0.80,
      h * 0.62,
      w * 0.62,
      h * 0.42,
      w * 0.62,
      h * 0.22,
    );
    bellPath.close();

    // Subtle glass body fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.30),
          primaryColor.withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(bellPath, fillPaint);

    // Bell stroke outline
    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bellPath, strokePaint);

    // Flared horizontal lip bar
    final lipPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.16, h * 0.73),
      Offset(w * 0.84, h * 0.73),
      lipPaint,
    );

    // Clapper pendulum (glowing accent jewel)
    final clapperPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.84), w * 0.10, clapperPaint);

    // Acoustic soundwave arcs if enabled
    if (hasRipples) {
      final ripplePaint = Paint()
        ..color = accentColor.withValues(alpha: 0.65)
        ..strokeWidth = w * 0.065
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Left ripple arc
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.46), radius: w * 0.42),
        math.pi * 0.90,
        math.pi * 0.35,
        false,
        ripplePaint,
      );

      // Right ripple arc
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.46), radius: w * 0.42),
        -math.pi * 0.25,
        math.pi * 0.35,
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

/// Unique handcrafted vector icon for "Setiap Hari" (Daily recurring repeat).
/// Features dual orbital arrows forming an infinity loop around a central time node.
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
    final radius = w * 0.36;

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

    // Center time dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.09, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _DailyRepeatPainter oldDelegate) =>
      oldDelegate.color != color;
}
