import 'package:flutter/material.dart';
import '../models/forecast_models.dart';
import 'xsec_painter.dart';

class XSecTab extends StatelessWidget {
  final ForecastResult forecast;

  const XSecTab({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return Card.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${forecast.cityName} · ${forecast.eventNameCn}截面',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '方位角 ${forecast.azimuth}°',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: CustomPaint(
                  painter: XSectionPainter(
                    res: forecast,
                    isLight: isLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
