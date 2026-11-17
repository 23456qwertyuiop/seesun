import 'package:flutter/material.dart';
import 'liquid_glass_painters.dart';

/// Independent morphing liquid glass capsule representing the active selection lens.
class LiquidGlassLens extends StatelessWidget {
  final double left;
  final double width;
  final double scaleX;
  final double scaleY;
  final double stretch;
  final double press;
  final bool isLight;
  final double specularOpacity;

  const LiquidGlassLens({
    super.key,
    required this.left,
    required this.width,
    required this.scaleX,
    required this.scaleY,
    required this.stretch,
    required this.press,
    required this.isLight,
    required this.specularOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      width: width,
      child: RepaintBoundary(
        child: Transform.scale(
          scaleX: scaleX,
          scaleY: scaleY,
          child: CustomPaint(
            painter: LiquidGlassLensPainter(
              isLight: isLight,
              stretch: stretch,
              press: press,
              specularOpacity: specularOpacity,
            ),
          ),
        ),
      ),
    );
  }
}
