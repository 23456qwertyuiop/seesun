import 'package:flutter/material.dart';
import '../models/forecast_models.dart';

class LabTab extends StatelessWidget {
  final TextEditingController lonController;
  final TextEditingController latController;
  final TextEditingController heightController;
  final String labEvent;
  final ManhattanhengeResult result;
  final VoidCallback onLocate;
  final ValueChanged<String> onEventChanged;
  final VoidCallback onCalculate;

  const LabTab({
    super.key,
    required this.lonController,
    required this.latController,
    required this.heightController,
    required this.labEvent,
    required this.result,
    required this.onLocate,
    required this.onEventChanged,
    required this.onCalculate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                  '悬日计算器',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                FilledButton.tonalIcon(
                  onPressed: onLocate,
                  icon: const Icon(Icons.my_location_rounded, size: 16),
                  label: const Text('当前定位', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: lonController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        style: const TextStyle(fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          labelText: '经度 (°E)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        style: const TextStyle(fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          labelText: '纬度 (°N)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          labelText: '离地高度 (m)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: labEvent,
                        decoration: const InputDecoration(
                          labelText: '事件',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'sunset', child: Text('日落')),
                          DropdownMenuItem(value: 'sunrise', child: Text('日出')),
                        ],
                        onChanged: (v) {
                          if (v != null) onEventChanged(v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onCalculate,
                  child: const Text('计算悬日'),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      _ResultRow(label: '地平线方位角', value: result.azimuthDisplay),
                      const Divider(height: 16),
                      _ResultRow(label: '视地平修正角', value: result.dipDisplay),
                      const Divider(height: 16),
                      _ResultRow(label: '时刻', value: result.timeDisplay),
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
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
