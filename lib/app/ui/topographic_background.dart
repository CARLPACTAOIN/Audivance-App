import 'package:flutter/material.dart';

/// A reusable dark textured background featuring organic topographic contour lines
/// and a warm ambient glow, designed for Audivance welcome and onboarding screens.
class AudivanceBackground extends StatelessWidget {
  const AudivanceBackground({
    super.key,
    required this.child,
    this.showContour = true,
    this.showGlow = true,
    this.glowAlignment = const Alignment(0.0, -0.38),
    this.backgroundColor = const Color(0xFF0D1117),
  });

  final Widget child;
  final bool showContour;
  final bool showGlow;
  final Alignment glowAlignment;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid dark foundation
        ColoredBox(color: backgroundColor),

        // Atmospheric warm amber radial glow
        if (showGlow)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: glowAlignment,
                  radius: 0.72,
                  colors: [
                    const Color(0xFFD97706).withValues(alpha: 0.12),
                    const Color(0xFFD97706).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),

        // Decorative topographic contour lines
        if (showContour)
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: TopographicPainter()),
            ),
          ),

        // Screen content
        child,
      ],
    );
  }
}

/// Fast, static CustomPainter that renders subtle topographic / elevation curves.
class TopographicPainter extends CustomPainter {
  const TopographicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Linear fade gradient for the lines: visible in upper half, smoothly fading out towards bottom
    final shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x38D97706), // Warm amber accent at the top
        Color(0x3094A3B8), // Slate gray
        Color(0x18475569), // Muted dark slate
        Color(0x00000000), // Transparent fade-out
      ],
      stops: [0.0, 0.28, 0.58, 0.88],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    // Secondary paint for deeper background contours
    final subShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x24D97706), Color(0x2264748B), Color(0x00000000)],
      stops: [0.0, 0.45, 0.82],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final subPaint = Paint()
      ..shader = subShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..isAntiAlias = true;

    // Set of flowing organic topographic contour lines
    final p1 = Path()
      ..moveTo(-w * 0.1, h * 0.08)
      ..cubicTo(w * 0.25, h * 0.03, w * 0.65, h * 0.14, w * 1.1, h * 0.06);
    canvas.drawPath(p1, paint);

    final p2 = Path()
      ..moveTo(-w * 0.15, h * 0.14)
      ..cubicTo(w * 0.2, h * 0.07, w * 0.55, h * 0.20, w * 1.15, h * 0.11);
    canvas.drawPath(p2, subPaint);

    final p3 = Path()
      ..moveTo(-w * 0.1, h * 0.21)
      ..cubicTo(w * 0.18, h * 0.12, w * 0.42, h * 0.26, w * 0.85, h * 0.18)
      ..cubicTo(w * 0.98, h * 0.16, w * 1.08, h * 0.22, w * 1.15, h * 0.24);
    canvas.drawPath(p3, paint);

    // Inner loops hugging around the upper-middle logo center (w*0.5, h*0.32)
    final p4 = Path()
      ..moveTo(-w * 0.05, h * 0.28)
      ..cubicTo(w * 0.15, h * 0.20, w * 0.32, h * 0.18, w * 0.50, h * 0.19)
      ..cubicTo(w * 0.72, h * 0.20, w * 0.88, h * 0.28, w * 1.1, h * 0.31);
    canvas.drawPath(p4, subPaint);

    final p5 = Path()
      ..moveTo(-w * 0.1, h * 0.35)
      ..cubicTo(w * 0.12, h * 0.28, w * 0.28, h * 0.24, w * 0.50, h * 0.25)
      ..cubicTo(w * 0.70, h * 0.26, w * 0.86, h * 0.36, w * 1.12, h * 0.39);
    canvas.drawPath(p5, paint);

    // Concentric elevation contours enclosing the logo halo
    final p6 = Path()
      ..moveTo(w * 0.02, h * 0.44)
      ..cubicTo(w * 0.20, h * 0.36, w * 0.30, h * 0.31, w * 0.50, h * 0.31)
      ..cubicTo(w * 0.70, h * 0.31, w * 0.82, h * 0.42, w * 1.05, h * 0.48);
    canvas.drawPath(p6, subPaint);

    // Lower sweeping contours
    final p7 = Path()
      ..moveTo(-w * 0.08, h * 0.52)
      ..cubicTo(w * 0.18, h * 0.45, w * 0.35, h * 0.41, w * 0.52, h * 0.43)
      ..cubicTo(w * 0.72, h * 0.45, w * 0.85, h * 0.55, w * 1.15, h * 0.58);
    canvas.drawPath(p7, paint);

    final p8 = Path()
      ..moveTo(-w * 0.1, h * 0.62)
      ..cubicTo(w * 0.22, h * 0.54, w * 0.45, h * 0.52, w * 0.68, h * 0.56)
      ..cubicTo(w * 0.88, h * 0.60, w * 1.02, h * 0.68, w * 1.12, h * 0.70);
    canvas.drawPath(p8, subPaint);

    // Subtle topographical ridge curves on the sides
    final leftRidge = Path()
      ..moveTo(-w * 0.05, h * 0.02)
      ..cubicTo(w * 0.15, h * 0.15, w * 0.10, h * 0.35, -w * 0.02, h * 0.48);
    canvas.drawPath(leftRidge, subPaint);

    final rightRidge = Path()
      ..moveTo(w * 1.05, h * 0.05)
      ..cubicTo(w * 0.88, h * 0.18, w * 0.92, h * 0.38, w * 1.08, h * 0.52);
    canvas.drawPath(rightRidge, subPaint);
  }

  @override
  bool shouldRepaint(covariant TopographicPainter oldDelegate) => false;
}
