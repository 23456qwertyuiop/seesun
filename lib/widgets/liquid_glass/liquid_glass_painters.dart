import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Draws the outer Liquid Glass dock rim, specular reflections, and soft shadow.
class LiquidGlassDockPainter extends CustomPainter {
  final bool isLight;
  final double borderRadius;
  final double specularOpacity;

  const LiquidGlassDockPainter({
    required this.isLight,
    required this.borderRadius,
    required this.specularOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Subtle inner depth gradient (top refraction sheen -> bottom ambient)
    final innerGradient = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(0, size.height),
      isLight
          ? [
              Colors.white.withValues(alpha: 0.42),
              Colors.white.withValues(alpha: 0.14),
              const Color(0xFFE8E8ED).withValues(alpha: 0.22),
            ]
          : [
              Colors.white.withValues(alpha: 0.11),
              Colors.white.withValues(alpha: 0.03),
              Colors.black.withValues(alpha: 0.18),
            ],
      const [0.0, 0.48, 1.0],
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = innerGradient
        ..style = PaintingStyle.fill,
    );

    // Directional glass rim highlight (top-left bright specular -> bottom-right subtle)
    final rimGradient = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width * 0.65, size.height),
      isLight
          ? [
              Colors.white.withValues(alpha: (specularOpacity * 3.4).clamp(0.0, 0.95)),
              Colors.white.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.08),
            ]
          : [
              Colors.white.withValues(alpha: (specularOpacity * 1.4).clamp(0.0, 0.42)),
              Colors.white.withValues(alpha: 0.09),
              Colors.white.withValues(alpha: 0.16),
            ],
      const [0.0, 0.55, 1.0],
    );

    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..shader = rimGradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant LiquidGlassDockPainter oldDelegate) =>
      oldDelegate.isLight != isLight ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.specularOpacity != specularOpacity;
}

/// Draws the independent floating glass lens capsule with specular edge & inner sheen.
class LiquidGlassLensPainter extends CustomPainter {
  final bool isLight;
  final double stretch;
  final double press;
  final double specularOpacity;

  const LiquidGlassLensPainter({
    required this.isLight,
    required this.stretch,
    required this.press,
    required this.specularOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height * 0.5);
    final rrect = RRect.fromRectAndRadius(rect, radius);

    // Soft elevation shadow beneath the lens
    final shadowPaint = Paint()
      ..color = isLight
          ? Colors.black.withValues(alpha: 0.10 + press * 0.04)
          : Colors.black.withValues(alpha: 0.38 + press * 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rrect.shift(const Offset(0, 2.5)), shadowPaint);

    // Translucent lens body with vertical glass curvature gradient
    final bodyGradient = ui.Gradient.linear(
      Offset.zero,
      Offset(0, size.height),
      isLight
          ? [
              Colors.white.withValues(alpha: 0.92),
              Colors.white.withValues(alpha: 0.76),
              const Color(0xFFEAEAF0).withValues(alpha: 0.85),
            ]
          : [
              Colors.white.withValues(alpha: 0.22 + press * 0.05),
              Colors.white.withValues(alpha: 0.10),
              Colors.white.withValues(alpha: 0.15),
            ],
      const [0.0, 0.5, 1.0],
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = bodyGradient
        ..style = PaintingStyle.fill,
    );

    // Subtle top specular arc inside the lens
    final topArcRect = Rect.fromLTWH(
      size.width * 0.12,
      2.0,
      size.width * 0.76,
      size.height * 0.28,
    );
    final topArcPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, topArcRect.top),
        Offset(0, topArcRect.bottom),
        [
          Colors.white.withValues(alpha: isLight ? 0.85 : 0.20),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topArcRect, Radius.circular(size.height * 0.25)),
      topArcPaint,
    );

    // Crisp specular rim border
    final rimGradient = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width * 0.5, size.height),
      isLight
          ? [
              Colors.white,
              Colors.white.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.06),
            ]
          : [
              Colors.white.withValues(alpha: (0.34 + stretch * 0.25).clamp(0.0, 0.55)),
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.24),
            ],
      const [0.0, 0.55, 1.0],
    );

    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..shader = rimGradient
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant LiquidGlassLensPainter oldDelegate) =>
      oldDelegate.isLight != isLight ||
      oldDelegate.stretch != stretch ||
      oldDelegate.press != press ||
      oldDelegate.specularOpacity != specularOpacity;
}
