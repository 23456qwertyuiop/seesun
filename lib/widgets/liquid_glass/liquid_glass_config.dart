import 'package:flutter/physics.dart';

/// Configuration for the FlClash-style Liquid Glass bottom navigation bar.
class LiquidGlassConfig {
  /// Gaussian blur sigma for the backdrop behind the dock.
  final double blurSigma;

  /// UV refraction strength in pixels used by the GLSL Fragment Shader.
  final double refractionStrength;

  /// Base translucency of the outer glass dock (0.0 - 1.0).
  final double glassOpacity;

  /// Intensity of specular rim highlights (0.0 - 1.0).
  final double specularOpacity;

  /// Scale multiplier applied to the moving lens while dragging.
  final double lensScaleOnDrag;

  /// Height of the floating dock capsule.
  final double dockHeight;

  /// Corner radius of the outer dock capsule.
  final double borderRadius;

  /// Horizontal margin around the floating dock.
  final double horizontalMargin;

  /// Maximum width of the dock on wide/desktop screens.
  final double maxWidth;

  /// Spring physics parameters for lens translation.
  final double springMass;
  final double springStiffness;
  final double springDamping;

  /// Forces standard frosted blur fallback without GLSL refraction shader.
  final bool lowPerformanceMode;

  const LiquidGlassConfig({
    this.blurSigma = 28.0,
    this.refractionStrength = 6.5,
    this.glassOpacity = 0.72,
    this.specularOpacity = 0.24,
    this.lensScaleOnDrag = 1.06,
    this.dockHeight = 64.0,
    this.borderRadius = 32.0,
    this.horizontalMargin = 16.0,
    this.maxWidth = 480.0,
    this.springMass = 1.0,
    this.springStiffness = 260.0,
    this.springDamping = 19.0,
    this.lowPerformanceMode = false,
  });

  SpringDescription get springDescription => SpringDescription(
        mass: springMass,
        stiffness: springStiffness,
        damping: springDamping,
      );
}
