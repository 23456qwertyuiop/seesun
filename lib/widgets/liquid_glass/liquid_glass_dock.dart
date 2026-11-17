import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'liquid_glass_config.dart';
import 'liquid_glass_lens.dart';
import 'liquid_glass_painters.dart';

/// Item descriptor for [LiquidGlassDock].
class LiquidGlassDockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LiquidGlassDockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// FlClash-inspired Liquid Glass floating bottom navigation bar.
///
/// Combines:
/// - `BackdropFilter` blur + GLSL `FragmentProgram` refraction (with automatic
///   frosted-blur fallback when shader filters are unsupported or
///   [LiquidGlassConfig.lowPerformanceMode] is enabled).
/// - `SpringSimulation` elastic translation & velocity-driven morphing.
/// - `CustomPainter` directional specular rims and soft elevation shadows.
/// - `RepaintBoundary` isolation for 60/120 FPS performance.
class LiquidGlassDock extends StatefulWidget {
  final int currentIndex;
  final List<LiquidGlassDockItem> items;
  final ValueChanged<int> onChanged;
  final LiquidGlassConfig config;

  const LiquidGlassDock({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onChanged,
    this.config = const LiquidGlassConfig(),
  });

  @override
  State<LiquidGlassDock> createState() => _LiquidGlassDockState();
}

class _LiquidGlassDockState extends State<LiquidGlassDock>
    with TickerProviderStateMixin {
  late final AnimationController _posController;
  late final AnimationController _jellyController;
  late final AnimationController _pressController;

  ui.FragmentProgram? _program;
  double _indicatorPos = 0;
  double _velocity = 0;
  bool _isDragging = false;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _indicatorPos = widget.currentIndex.toDouble();

    _posController = AnimationController.unbounded(vsync: this)
      ..value = _indicatorPos
      ..addListener(() {
        setState(() {
          _velocity = _posController.value - _indicatorPos;
          _indicatorPos = _posController.value;
        });
      });

    _jellyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _loadShader();
  }

  Future<void> _loadShader() async {
    if (widget.config.lowPerformanceMode) return;
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass.frag',
      );
      if (mounted) {
        setState(() => _program = program);
      }
    } catch (_) {
      // Graceful fallback to standard frosted BackdropFilter
    }
  }

  @override
  void didUpdateWidget(covariant LiquidGlassDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animateToIndex(widget.currentIndex);
    }
    if (oldWidget.config.lowPerformanceMode != widget.config.lowPerformanceMode &&
        !widget.config.lowPerformanceMode &&
        _program == null) {
      _loadShader();
    }
  }

  @override
  void dispose() {
    _posController.dispose();
    _jellyController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _animateToIndex(int index, {double initialVelocity = 0}) {
    final simulation = SpringSimulation(
      widget.config.springDescription,
      _indicatorPos,
      index.toDouble(),
      initialVelocity,
    );
    _posController.animateWith(simulation);
    _jellyController.forward(from: 0);
  }

  int _indexFromDx(double dx, double totalWidth) {
    final count = widget.items.length;
    final slotWidth = totalWidth / count;
    return (dx / slotWidth).floor().clamp(0, count - 1);
  }

  ui.ImageFilter _buildBackdropFilter({
    required double dockWidth,
    required double dockHeight,
    required double lensCenterX,
    required double lensWidth,
    required double stretch,
    required double press,
    required bool isLight,
  }) {
    final sigma = widget.config.lowPerformanceMode
        ? math.min(16.0, widget.config.blurSigma)
        : widget.config.blurSigma;
    final blurFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

    final program = _program;
    if (!widget.config.lowPerformanceMode &&
        program != null &&
        ui.ImageFilter.isShaderFilterSupported) {
      final shader = program.fragmentShader();
      shader.setFloat(0, dockWidth);
      shader.setFloat(1, dockHeight);
      shader.setFloat(2, lensCenterX);
      shader.setFloat(3, lensWidth);
      shader.setFloat(4, math.max(12.0, dockHeight - 10.0));
      shader.setFloat(5, stretch);
      shader.setFloat(6, press);
      shader.setFloat(7, isLight ? 1.0 : 0.0);
      shader.setFloat(8, widget.config.refractionStrength);

      return ui.ImageFilter.compose(
        outer: ui.ImageFilter.shader(shader),
        inner: blurFilter,
      );
    }

    return blurFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final cs = theme.colorScheme;
    final cfg = widget.config;
    final count = widget.items.length;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        cfg.horizontalMargin,
        0,
        cfg.horizontalMargin,
        math.max(12.0, bottomPadding + 6),
      ),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cfg.maxWidth),
          child: RepaintBoundary(
            child: Container(
              height: cfg.dockHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cfg.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.65),
                    blurRadius: 28,
                    spreadRadius: -2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, outerConstraints) {
                  final dockWidth = outerConstraints.maxWidth;
                  const innerPad = 5.0;
                  final trackWidth = math.max(1.0, dockWidth - innerPad * 2);
                  final slotWidth = trackWidth / count;

                  return AnimatedBuilder(
                    animation: Listenable.merge([_jellyController, _pressController]),
                    builder: (context, _) {
                      final travelDist =
                          (_indicatorPos - _indicatorPos.round()).abs();
                      final speedStretch =
                          (_velocity.abs() * 4.2).clamp(0.0, 0.26);
                      final jellyWave =
                          math.sin(_jellyController.value * math.pi) * 0.09;
                      final stretchX =
                          (travelDist * 0.32 + speedStretch + jellyWave)
                              .clamp(0.0, 0.34);

                      final pressVal = _pressController.value;
                      final pillWidth = slotWidth * (1.0 + stretchX);
                      final clampedPos =
                          _indicatorPos.clamp(-0.14, count - 1 + 0.14);
                      final centerOffset = (clampedPos + 0.5) * slotWidth;
                      final pillLeft = (centerOffset - pillWidth / 2)
                          .clamp(0.0, trackWidth - pillWidth);

                      final dragScale = _isDragging
                          ? cfg.lensScaleOnDrag
                          : (1.0 + pressVal * 0.03);
                      final squishY = (1.0 - stretchX * 0.15) * dragScale;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(cfg.borderRadius),
                        child: BackdropFilter(
                          filter: _buildBackdropFilter(
                            dockWidth: dockWidth,
                            dockHeight: cfg.dockHeight,
                            lensCenterX: innerPad + pillLeft + pillWidth * 0.5,
                            lensWidth: pillWidth,
                            stretch: stretchX,
                            press: pressVal,
                            isLight: isLight,
                          ),
                          child: CustomPaint(
                            painter: LiquidGlassDockPainter(
                              isLight: isLight,
                              borderRadius: cfg.borderRadius,
                              specularOpacity: cfg.specularOpacity,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(innerPad),
                              color: isLight
                                  ? Colors.white.withValues(alpha: cfg.glassOpacity * 0.55)
                                  : const Color(0xFF141418).withValues(alpha: cfg.glassOpacity),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onHorizontalDragStart: (_) {
                                  _posController.stop();
                                  _pressController.forward();
                                  setState(() => _isDragging = true);
                                },
                                onHorizontalDragUpdate: (details) {
                                  final nextPos =
                                      (details.localPosition.dx / slotWidth - 0.5)
                                          .clamp(-0.10, count - 1 + 0.10);
                                  setState(() {
                                    _velocity = nextPos - _indicatorPos;
                                    _indicatorPos = nextPos;
                                    _posController.value = nextPos;
                                  });
                                  final hoverIdx = _indexFromDx(
                                    details.localPosition.dx,
                                    trackWidth,
                                  );
                                  if (hoverIdx != widget.currentIndex) {
                                    widget.onChanged(hoverIdx);
                                  }
                                },
                                onHorizontalDragEnd: (details) {
                                  final vx = details.velocity.pixelsPerSecond.dx /
                                      slotWidth;
                                  final projected = (_indicatorPos + vx * 0.085)
                                      .round()
                                      .clamp(0, count - 1);
                                  _pressController.reverse();
                                  setState(() => _isDragging = false);
                                  if (projected != widget.currentIndex) {
                                    widget.onChanged(projected);
                                  }
                                  _animateToIndex(
                                    projected,
                                    initialVelocity: vx.clamp(-10.0, 10.0),
                                  );
                                },
                                onHorizontalDragCancel: () {
                                  _pressController.reverse();
                                  setState(() => _isDragging = false);
                                  _animateToIndex(widget.currentIndex);
                                },
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    // Independent moving glass lens
                                    LiquidGlassLens(
                                      left: pillLeft,
                                      width: pillWidth,
                                      scaleX: dragScale,
                                      scaleY: squishY,
                                      stretch: stretchX,
                                      press: pressVal,
                                      isLight: isLight,
                                      specularOpacity: cfg.specularOpacity,
                                    ),

                                    // Navigation items
                                    Row(
                                      children: List.generate(count, (i) {
                                        final item = widget.items[i];
                                        final dist = (_indicatorPos - i).abs();
                                        final focus = (1.0 - dist).clamp(0.0, 1.0);
                                        final isSelected =
                                            widget.currentIndex == i;
                                        final isPressed = _pressedIndex == i;

                                        final itemColor = Color.lerp(
                                          cs.onSurfaceVariant,
                                          cs.onSurface,
                                          focus,
                                        )!;
                                        final iconScale =
                                            (1.0 + focus * 0.14) *
                                                (isPressed ? 0.90 : 1.0);

                                        return Expanded(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTapDown: (_) {
                                              _pressController.forward();
                                              setState(() => _pressedIndex = i);
                                            },
                                            onTapUp: (_) {
                                              _pressController.reverse();
                                              setState(() => _pressedIndex = null);
                                            },
                                            onTapCancel: () {
                                              _pressController.reverse();
                                              setState(() => _pressedIndex = null);
                                            },
                                            onTap: () {
                                              if (i != widget.currentIndex) {
                                                widget.onChanged(i);
                                              } else {
                                                _animateToIndex(i);
                                              }
                                            },
                                            child: AnimatedScale(
                                              scale: isPressed ? 0.93 : 1.0,
                                              duration: const Duration(
                                                  milliseconds: 110),
                                              curve: Curves.easeOutCubic,
                                              child: SizedBox(
                                                height: double.infinity,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Transform.scale(
                                                      scale: iconScale,
                                                      child: Icon(
                                                        isSelected
                                                            ? item.activeIcon
                                                            : item.icon,
                                                        size: 19,
                                                        color: itemColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item.label,
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: focus > 0.5
                                                            ? FontWeight.w600
                                                            : FontWeight.w500,
                                                        color: itemColor,
                                                        letterSpacing: -0.1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
