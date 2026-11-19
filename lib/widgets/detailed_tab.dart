import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/forecast_models.dart';
import '../services/sun_calculator.dart';

class DetailedTab extends StatelessWidget {
  final ForecastResult forecast;
  final List<DailyTrendPoint> weeklyTrend;
  final VoidCallback onBack;
  final ValueChanged<String> onSelectEvent;

  const DetailedTab({
    super.key,
    required this.forecast,
    required this.weeklyTrend,
    required this.onBack,
    required this.onSelectEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final events = ['rise_1', 'set_1', 'rise_2', 'set_2']
        .map((ev) => computeForecast(forecast.cityName, ev, forecast.modelCode))
        .toList();

    final isSunrise = forecast.eventCode.startsWith('rise');
    final bestDay = weeklyTrend.isEmpty
        ? null
        : weeklyTrend.reduce((a, b) => a.quality >= b.quality ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card.outlined(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${forecast.cityName} · ${forecast.eventNameCn}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('返回'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(label: '高云 (HCC)', value: '${forecast.hcc}%'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(label: '中云 (MCC)', value: '${forecast.mcc}%'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(label: '低云 (LCC)', value: '${forecast.lcc}%'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricCard(label: '太阳方位角', value: '${forecast.azimuth}°'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Table(
                        border: TableBorder.all(color: cs.outlineVariant, width: 1),
                        columnWidths: const {
                          0: FlexColumnWidth(1.3),
                          1: FlexColumnWidth(1.0),
                          2: FlexColumnWidth(1.0),
                          3: FlexColumnWidth(0.9),
                          4: FlexColumnWidth(1.5),
                          5: FlexColumnWidth(1.0),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                            ),
                            children: [
                              _th(context, '时次'),
                              _th(context, '时刻'),
                              _th(context, '鲜艳度'),
                              _th(context, 'AOD'),
                              _th(context, '高/中/低云'),
                              _th(context, '等级'),
                            ],
                          ),
                          ...events.map((item) {
                            final isSelected = item.eventCode == forecast.eventCode;
                            return TableRow(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.onSurface.withValues(alpha: 0.08)
                                    : Colors.transparent,
                              ),
                              children: [
                                _td(item.eventNameCn, bold: true, onTap: () => onSelectEvent(item.eventCode)),
                                _td(
                                  item.eventTime.length >= 5 ? item.eventTime.substring(0, 5) : item.eventTime,
                                  mono: true,
                                  onTap: () => onSelectEvent(item.eventCode),
                                ),
                                _td(
                                  item.quality.toStringAsFixed(2),
                                  mono: true,
                                  bold: true,
                                  onTap: () => onSelectEvent(item.eventCode),
                                ),
                                _td(item.aod.toStringAsFixed(2), mono: true, onTap: () => onSelectEvent(item.eventCode)),
                                _td('${item.hcc}/${item.mcc}/${item.lcc}%', mono: true, onTap: () => onSelectEvent(item.eventCode)),
                                _td(item.qualityTag, onTap: () => onSelectEvent(item.eventCode)),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 未来 7 天鲜艳度趋势
        Card.outlined(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '未来 7 天${isSunrise ? "日出" : "日落"}趋势',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (bestDay != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '最佳: ${bestDay.dateLabel} (${bestDay.quality.toStringAsFixed(2)})',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: weeklyTrend.isEmpty
                    ? const SizedBox(height: 130)
                    : SizedBox(
                        height: 150,
                        child: CustomPaint(
                          painter: _WeeklyTrendPainter(
                            points: weeklyTrend,
                            fg: cs.onSurface,
                            muted: cs.onSurfaceVariant,
                            grid: cs.outlineVariant,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _th(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _td(
    String text, {
    bool bold = false,
    bool mono = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: mono ? 'monospace' : null,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _WeeklyTrendPainter extends CustomPainter {
  final List<DailyTrendPoint> points;
  final Color fg;
  final Color muted;
  final Color grid;

  _WeeklyTrendPainter({
    required this.points,
    required this.fg,
    required this.muted,
    required this.grid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const padL = 18.0;
    const padR = 18.0;
    const padT = 22.0;
    const padB = 26.0;
    final plotW = size.width - padL - padR;
    final plotH = size.height - padT - padB;
    const maxQ = 1.65;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    for (final refQ in [0.4, 0.8, 1.2]) {
      final y = padT + plotH - (refQ / maxQ) * plotH;
      canvas.drawLine(Offset(padL, y), Offset(padL + plotW, y), gridPaint);
    }

    final coords = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? padL + plotW / 2
          : padL + (i / (points.length - 1)) * plotW;
      final normQ = (points[i].quality / maxQ).clamp(0.04, 1.0);
      final y = padT + plotH - normQ * plotH;
      coords.add(Offset(x, y));
    }

    // Fill area under curve
    final areaPath = Path()..moveTo(coords.first.dx, padT + plotH);
    for (int i = 0; i < coords.length; i++) {
      if (i == 0) {
        areaPath.lineTo(coords[i].dx, coords[i].dy);
      } else {
        final prev = coords[i - 1];
        final curr = coords[i];
        final midX = (prev.dx + curr.dx) / 2;
        areaPath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
      }
    }
    areaPath.lineTo(coords.last.dx, padT + plotH);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()..color = fg.withValues(alpha: 0.08),
    );

    // Smooth curve stroke
    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (int i = 1; i < coords.length; i++) {
      final prev = coords[i - 1];
      final curr = coords[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = fg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Dots + value labels + day labels
    final maxPoint = points.map((e) => e.quality).reduce(math.max);

    for (int i = 0; i < points.length; i++) {
      final c = coords[i];
      final pt = points[i];
      final isBest = pt.quality == maxPoint;

      canvas.drawCircle(c, isBest ? 4.5 : 3.2, Paint()..color = fg);

      // Score above point
      final scoreTp = TextPainter(
        text: TextSpan(
          text: pt.quality.toStringAsFixed(2),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: isBest ? FontWeight.w700 : FontWeight.w500,
            color: isBest ? fg : muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      scoreTp.paint(canvas, Offset(c.dx - scoreTp.width / 2, c.dy - 16));

      // Day label below axis
      final dayTp = TextPainter(
        text: TextSpan(
          text: pt.dateLabel,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
            color: i == 0 ? fg : muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dayTp.paint(canvas, Offset(c.dx - dayTp.width / 2, size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyTrendPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.fg != fg;
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
