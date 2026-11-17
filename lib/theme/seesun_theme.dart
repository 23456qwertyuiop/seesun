import 'dart:ui';
import 'package:flutter/material.dart';

class SeesunColors {
  final bool isLight;
  final Color bgBase;
  final Color glassBg;
  final Color glassBgHeavy;
  final Color glassBgLight;
  final Color glassBgHover;
  final Color glassPill;
  final Color glassBorder;
  final Color glassBorderStrong;
  final Color glassHighlight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentFg;
  final Color accentBg;
  final Color divider;
  final Color shadowGlass;

  const SeesunColors._({
    required this.isLight,
    required this.bgBase,
    required this.glassBg,
    required this.glassBgHeavy,
    required this.glassBgLight,
    required this.glassBgHover,
    required this.glassPill,
    required this.glassBorder,
    required this.glassBorderStrong,
    required this.glassHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentFg,
    required this.accentBg,
    required this.divider,
    required this.shadowGlass,
  });

  static const dark = SeesunColors._(
    isLight: false,
    bgBase: Color(0xFF0B0B0D),
    glassBg: Color(0x9E1C1C20),
    glassBgHeavy: Color(0xC7141418),
    glassBgLight: Color(0x0FFFFFFF),
    glassBgHover: Color(0x1CFFFFFF),
    glassPill: Color(0x14FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    glassBorderStrong: Color(0x3DFFFFFF),
    glassHighlight: Color(0x24FFFFFF),
    textPrimary: Color(0xFFF4F4F6),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF6E6E77),
    accentFg: Color(0xFFFFFFFF),
    accentBg: Color(0xFF09090B),
    divider: Color(0x14FFFFFF),
    shadowGlass: Color(0x73000000),
  );

  static const light = SeesunColors._(
    isLight: true,
    bgBase: Color(0xFFE6E6EB),
    glassBg: Color(0x9EFFFFFF),
    glassBgHeavy: Color(0xD1FAFAFC),
    glassBgLight: Color(0x0B000000),
    glassBgHover: Color(0x16000000),
    glassPill: Color(0x11000000),
    glassBorder: Color(0x1C000000),
    glassBorderStrong: Color(0x3D000000),
    glassHighlight: Color(0xCCFFFFFF),
    textPrimary: Color(0xFF141417),
    textSecondary: Color(0xFF52525B),
    textMuted: Color(0xFF868690),
    accentFg: Color(0xFF18181B),
    accentBg: Color(0xFFFAFAFA),
    divider: Color(0x14000000),
    shadowGlass: Color(0x14000000),
  );
}

class GlassCard extends StatelessWidget {
  final SeesunColors colors;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Clip clipBehavior;

  const GlassCard({
    super.key,
    required this.colors,
    required this.child,
    this.padding,
    this.radius = 18,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors.shadowGlass,
            blurRadius: colors.isLight ? 28 : 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: colors.glassBg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: colors.glassBorder, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GlassSubcard extends StatelessWidget {
  final SeesunColors colors;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const GlassSubcard({
    super.key,
    required this.colors,
    required this.child,
    this.padding,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.glassBgLight,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AmbientBackground extends StatelessWidget {
  final SeesunColors colors;

  const AmbientBackground({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    final orbColor1 = colors.isLight
        ? const Color(0xEBFFFFFF)
        : const Color(0x12FFFFFF);
    final orbColor2 = colors.isLight
        ? const Color(0xEBFFFFFF)
        : const Color(0x0DFFFFFF);
    final orbColor3 = colors.isLight
        ? const Color(0xEBFFFFFF)
        : const Color(0x0FFFFFFF);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: colors.bgBase,
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: _BlurredOrb(size: 240, color: orbColor1),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.32,
            left: -100,
            child: _BlurredOrb(size: 280, color: orbColor2),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.12,
            right: -50,
            child: _BlurredOrb(size: 220, color: orbColor3),
          ),
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.glassBorder.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -220,
            child: CustomPaint(
              size: const Size(500, 500),
              painter: _DashedCirclePainter(
                color: colors.glassBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurredOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurredOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 90;
    const step = (2 * 3.141592653589793) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * step,
        step * 0.5,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
