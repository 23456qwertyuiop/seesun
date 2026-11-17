import 'package:flutter/material.dart';
import '../models/forecast_models.dart';
import '../services/sun_calculator.dart';

class DetailedTab extends StatelessWidget {
  final ForecastResult forecast;
  final VoidCallback onBack;
  final ValueChanged<String> onSelectEvent;

  const DetailedTab({
    super.key,
    required this.forecast,
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

    return Card.outlined(
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
