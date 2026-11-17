import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../theme/seesun_theme.dart';

class LiquidDockItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LiquidDockItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class LiquidBottomDock extends StatefulWidget {
  final SeesunColors colors;
  final int currentIndex;
  final List<LiquidDockItemData> items;
  final ValueChanged<int> onChanged;

  const LiquidBottomDock({
    super.key,
    required this.colors,
    required this.currentIndex,
    required this.items,
    required this.onChanged,
  });

  @override
  State<LiquidBottomDock> createState() => _LiquidBottomDockState();
}

class _LiquidBottomDockState extends State<LiquidBottomDock>
    with TickerProviderStateMixin {
  late final AnimationController _posController;
  late final AnimationController _jellyController;

  double _indicatorPos = 0;
  double _velocity = 0;
  bool _isDragging = false;
  int? _pressedIndex;

  // Underdamped spring for silky iOS 26 / FlClash fluid overshoot & settle
  static const SpringDescription _fluidSpring = SpringDescription(
    mass: 1.0,
    stiffness: 260.0,
    damping: 18.5,
  );

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
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(covariant LiquidBottomDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      _animateToIndex(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _posController.dispose();
    _jellyController.dispose();
    super.dispose();
  }

  void _animateToIndex(int index, {double initialVelocity = 0}) {
    final simulation = SpringSimulation(
      _fluidSpring,
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

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final count = widget.items.length;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(12.0, bottomPadding + 6)),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: colors.isLight
                      ? const Color(0x24000000)
                      : const Color(0x99000000),
                  blurRadius: 32,
                  spreadRadius: -2,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors.isLight
                          ? [
                              const Color(0xD9FFFFFF),
                              const Color(0xB8F5F5F7),
                            ]
                          : [
                              const Color(0xD1222228),
                              const Color(0xBA141418),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: colors.isLight
                          ? const Color(0xCCFFFFFF)
                          : const Color(0x2EFFFFFF),
                      width: 1,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final trackWidth = constraints.maxWidth;
                      final slotWidth = trackWidth / count;

                      return AnimatedBuilder(
                        animation: _jellyController,
                        builder: (context, _) {
                          // Liquid stretch & squish physics
                          final travelDist =
                              (_indicatorPos - _indicatorPos.round()).abs();
                          final speedStretch =
                              (_velocity.abs() * 4.5).clamp(0.0, 0.28);
                          final jellyWave =
                              math.sin(_jellyController.value * math.pi) * 0.10;
                          final stretchX =
                              (travelDist * 0.34 + speedStretch + jellyWave)
                                  .clamp(0.0, 0.36);

                          final pillWidth = slotWidth * (1.0 + stretchX);
                          final clampedPos =
                              _indicatorPos.clamp(-0.15, count - 1 + 0.15);
                          final centerOffset = (clampedPos + 0.5) * slotWidth;
                          final pillLeft = (centerOffset - pillWidth / 2)
                              .clamp(0.0, trackWidth - pillWidth);

                          final dragScale = _isDragging ? 1.07 : 1.0;
                          final squishY =
                              (1.0 - stretchX * 0.16) * dragScale;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragStart: (details) {
                              _posController.stop();
                              setState(() {
                                _isDragging = true;
                              });
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
                              final vx =
                                  details.velocity.pixelsPerSecond.dx / slotWidth;
                              final projected = (_indicatorPos + vx * 0.09)
                                  .round()
                                  .clamp(0, count - 1);
                              setState(() {
                                _isDragging = false;
                              });
                              if (projected != widget.currentIndex) {
                                widget.onChanged(projected);
                              }
                              _animateToIndex(
                                projected,
                                initialVelocity: vx.clamp(-10.0, 10.0),
                              );
                            },
                            onHorizontalDragCancel: () {
                              setState(() => _isDragging = false);
                              _animateToIndex(widget.currentIndex);
                            },
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Sliding Liquid Glass Pill with Specular Rim
                                Positioned(
                                  left: pillLeft,
                                  top: 0,
                                  bottom: 0,
                                  width: pillWidth,
                                  child: Transform.scale(
                                    scaleX: dragScale,
                                    scaleY: squishY,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(27),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: colors.isLight
                                              ? [
                                                  const Color(0xF5FFFFFF),
                                                  const Color(0xCCEBEBF0),
                                                ]
                                              : [
                                                  const Color(0x36FFFFFF),
                                                  const Color(0x18FFFFFF),
                                                ],
                                        ),
                                        border: Border.all(
                                          color: colors.isLight
                                              ? const Color(0xFFFFFFFF)
                                              : const Color(0x47FFFFFF),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.isLight
                                                ? const Color(0x1A000000)
                                                : const Color(0x4D000000),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Tab Items
                                Row(
                                  children: List.generate(count, (i) {
                                    final item = widget.items[i];
                                    final dist = (_indicatorPos - i).abs();
                                    final focus = (1.0 - dist).clamp(0.0, 1.0);
                                    final isSelected = widget.currentIndex == i;
                                    final isPressed = _pressedIndex == i;

                                    final iconColor = Color.lerp(
                                      colors.textMuted,
                                      colors.textPrimary,
                                      focus,
                                    )!;
                                    final iconScale = (1.0 + focus * 0.16) *
                                        (isPressed ? 0.88 : 1.0);

                                    return Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapDown: (_) =>
                                            setState(() => _pressedIndex = i),
                                        onTapUp: (_) =>
                                            setState(() => _pressedIndex = null),
                                        onTapCancel: () =>
                                            setState(() => _pressedIndex = null),
                                        onTap: () {
                                          if (i != widget.currentIndex) {
                                            widget.onChanged(i);
                                          } else {
                                            _animateToIndex(i);
                                          }
                                        },
                                        child: AnimatedScale(
                                          scale: isPressed ? 0.92 : 1.0,
                                          duration:
                                              const Duration(milliseconds: 110),
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
                                                    color: iconColor,
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
                                                    color: iconColor,
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
                          );
                        },
                      );
                    },
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
