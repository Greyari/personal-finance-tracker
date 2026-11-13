import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../main.dart';

/// Ultra-Luxury Entrance Animation Screen.
/// Designed with Apple & Haute Horlogerie inspired Monochrome Luxury Glass aesthetic:
/// - Seamless cold-start: App launcher icon is unified directly inside the central frosted glass plaque
/// - High-precision rotating astronomical halo ring with watchmaker tick marks & emerald comet arc
/// - Atmospheric dark obsidian canvas with ambient breathing emerald & platinum orbs
/// - Dynamic liquid light sheen sweep across the glass plaque and icon
/// - Expanding typography with gold/emerald luxury diamond accents
/// - Zero white-flash: perfectly matches native Android 12+ launch background
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _haloController;
  late final AnimationController _sheenController;
  late final AnimationController _progressController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Ambient breathing loop for background light orbs (3.6s)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    // Continuous celestial rotation for the astronomical halo ring (14s)
    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 14000),
    )..repeat();

    // Sheen sweep across the luxury plaque & icon (extended 2.4s)
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    // Smooth luxury loading progress (3.8s)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..forward();

    // Auto navigate to AuthGate after 3.9 seconds (longer, elegant load)
    Future.delayed(const Duration(milliseconds: 3900), () {
      _proceed();
    });
  }

  void _proceed() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _haloController.dispose();
    _sheenController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0D14) : const Color(0xFFF8FAFC),
      body: GestureDetector(
        onTap: _proceed, // Tap anywhere to skip instantly
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Ambient breathing background light orbs
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                final breath = _ambientController.value;
                return CustomPaint(
                  size: size,
                  painter: _SplashAmbientPainter(
                    progress: breath,
                    isDark: isDark,
                  ),
                );
              },
            ),

            // Top-layer frosted glass blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Main Centered Content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Central Emblem Zone: Astronomical Ring + Frosted Glass Plaque housing App Icon
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating Astronomical Halo Ring (Swiss Watch / High Horology aesthetic)
                          AnimatedBuilder(
                            animation: _haloController,
                            builder: (context, _) {
                              return Transform.rotate(
                                angle: _haloController.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(164, 164),
                                  painter: _LuxuryOrbitalHaloPainter(isDark: isDark),
                                ),
                              );
                            },
                          ),

                          // Central Frosted Glass Plaque holding the App Icon with Animated Sheen
                          AnimatedBuilder(
                            animation: _sheenController,
                            builder: (context, child) {
                              return _LuxuryAppIconPlaque(
                                sheenProgress: _sheenController.value,
                                isDark: isDark,
                              );
                            },
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.78, 0.78),
                                end: const Offset(1.0, 1.0),
                                duration: 750.ms,
                                curve: Curves.easeOutBack,
                              )
                              .fadeIn(duration: 600.ms),
                        ],
                      ),
                    ),

                    const SizedBox(height: 38),

                    // Brand Title with Cinematic Letter Spacing
                    Text(
                      'PERSONAL FINANCE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.5,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: 10),

                    // Luxury Subtitle with Elegant Diamond Flares
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 1.2,
                          color: const Color(0xFF34D399).withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LUXURY WEALTH MANAGEMENT',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '✦',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 1.2,
                          color: const Color(0xFF34D399).withValues(alpha: 0.6),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                    const Spacer(flex: 3),

                    // Minimalist Luxury Hairline Loading Indicator (Pure elegance, no text)
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        return Container(
                          width: 140,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 140 * Curves.easeInOutCubic.transform(_progressController.value),
                              height: 2.5,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF059669),
                                    Color(0xFF34D399),
                                    Color(0xFFFFFFFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF34D399).withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 600.ms),

                    const SizedBox(height: 38),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted Glass Plaque encasing the App Icon with Animated Sheen Sweep
class _LuxuryAppIconPlaque extends StatelessWidget {
  final double sheenProgress;
  final bool isDark;

  const _LuxuryAppIconPlaque({
    required this.sheenProgress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34D399).withValues(alpha: isDark ? 0.28 : 0.18),
            blurRadius: 38,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: 0.40),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.70),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.90),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Inset App Icon - seamlessly encased in the luxury glass frame
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 44,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Diagonal Liquid Light Sheen Sweep Effect
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Transform.rotate(
                      angle: -math.pi / 5,
                      child: FractionalTranslation(
                        translation: Offset(sheenProgress * 3.2 - 1.6, 0),
                        child: Container(
                          width: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: isDark ? 0.45 : 0.70),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Delicate Top-Right Diamond Sparkle
                const Positioned(
                  top: 7,
                  right: 7,
                  child: CustomPaint(
                    size: Size(12, 12),
                    painter: _DiamondGlintPainter(
                      color: Color(0xFF34D399),
                    ),
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

/// Swiss-watch inspired astronomical halo ring with precision indices & glowing arc
class _LuxuryOrbitalHaloPainter extends CustomPainter {
  final bool isDark;

  const _LuxuryOrbitalHaloPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    const emerald = Color(0xFF34D399);

    // Subtle hairline track
    final trackPaint = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.12 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(center, radius, trackPaint);

    // Glowing emerald arc segment
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          emerald.withValues(alpha: 0.0),
          emerald.withValues(alpha: 0.75),
          emerald.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.50],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 0.7,
      false,
      arcPaint,
    );

    // Watchmaker index tick marks (16 subtle ticks around the circle)
    final tickPaint = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.25 : 0.20)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const tickCount = 16;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i * 2 * math.pi) / tickCount;
      final isMajor = i % 4 == 0;
      final innerRadius = radius - (isMajor ? 6.0 : 3.5);

      final p1 = Offset(center.dx + innerRadius * math.cos(angle), center.dy + innerRadius * math.sin(angle));
      final p2 = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));

      tickPaint.color = isMajor
          ? emerald.withValues(alpha: isDark ? 0.60 : 0.50)
          : primaryColor.withValues(alpha: isDark ? 0.22 : 0.16);
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LuxuryOrbitalHaloPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// 4-point Diamond Glint Painter
class _DiamondGlintPainter extends CustomPainter {
  final Color color;

  const _DiamondGlintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.62, h * 0.38)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.62, h * 0.62)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.38, h * 0.62)
      ..lineTo(0, h * 0.5)
      ..lineTo(w * 0.38, h * 0.38)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), 1.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _DiamondGlintPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Dynamic multi-orb ambient painter for splash background
class _SplashAmbientPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _SplashAmbientPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pulse factor based on sine wave
    final pulse = 0.90 + 0.20 * math.sin(progress * math.pi);

    // Orb 1: Upper Left Emerald Orb
    final orb1Center = Offset(w * 0.25, h * 0.32);
    final orb1Radius = (w * 0.55) * pulse;
    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF34D399).withValues(alpha: isDark ? 0.24 : 0.16),
          const Color(0xFF34D399).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: orb1Radius));
    canvas.drawCircle(orb1Center, orb1Radius, orb1Paint);

    // Orb 2: Center Right Silver/Slate Glow
    final orb2Center = Offset(w * 0.75, h * 0.48);
    final orb2Radius = (w * 0.50) * (2.0 - pulse);
    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
              .withValues(alpha: isDark ? 0.16 : 0.12),
          const Color(0xFF94A3B8).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius));
    canvas.drawCircle(orb2Center, orb2Radius, orb2Paint);

    // Orb 3: Bottom Teal Bloom
    final orb3Center = Offset(w * 0.50, h * 0.85);
    final orb3Radius = (w * 0.65) * pulse;
    final orb3Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF14B8A6).withValues(alpha: isDark ? 0.15 : 0.10),
          const Color(0xFF14B8A6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: orb3Center, radius: orb3Radius));
    canvas.drawCircle(orb3Center, orb3Radius, orb3Paint);
  }

  @override
  bool shouldRepaint(covariant _SplashAmbientPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
