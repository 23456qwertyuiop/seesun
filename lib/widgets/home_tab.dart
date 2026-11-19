import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/forecast_models.dart';
import '../services/sun_calculator.dart';

class HomeTab extends StatelessWidget {
  final bool isLocating;
  final String geoStatusText;
  final String selectedEvent;
  final String selectedModel;
  final TextEditingController cityController;
  final FocusNode cityFocusNode;
  final ForecastResult forecast;
  final VoidCallback onLocate;
  final ValueChanged<String> onEventChanged;
  final ValueChanged<String> onModelChanged;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final ValueChanged<String> onQuickCityTap;
  final ValueChanged<int> onSwitchTab;

  const HomeTab({
    super.key,
    required this.isLocating,
    required this.geoStatusText,
    required this.selectedEvent,
    required this.selectedModel,
    required this.cityController,
    required this.cityFocusNode,
    required this.forecast,
    required this.onLocate,
    required this.onEventChanged,
    required this.onModelChanged,
    required this.onSearch,
    required this.onClear,
    required this.onQuickCityTap,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pct = math.min(1.0, math.max(0.06, forecast.quality / 1.6));
    final isSunrise = forecast.eventCode.startsWith('rise');
    final isTomorrow = forecast.eventCode.endsWith('2');
    final photoWindows = computePhotoWindows(forecast.eventTime, isSunrise);
    final insightText = generateForecastInsight(forecast);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 定位与搜索控制卡
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 定位栏
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (isLocating)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onSurface,
                          ),
                        )
                      else
                        Icon(Icons.my_location_rounded, size: 16, color: cs.onSurface),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          geoStatusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: onLocate,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('定位', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 时次与数据源选择
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedEvent,
                        decoration: const InputDecoration(
                          labelText: '预报时次',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: kEventLabels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onEventChanged(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedModel,
                        decoration: const InputDecoration(
                          labelText: '数据源',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'EC', child: Text('EC')),
                          DropdownMenuItem(value: 'GFS', child: Text('GFS')),
                        ],
                        onChanged: (v) {
                          if (v != null) onModelChanged(v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 城市搜索
                Row(
                  children: [
                    Expanded(
                      child: RawAutocomplete<String>(
                        textEditingController: cityController,
                        focusNode: cityFocusNode,
                        optionsBuilder: (textEditingValue) {
                          final query = textEditingValue.text.trim();
                          if (query.isEmpty) return cityDb.keys;
                          return cityDb.keys.where((k) {
                            final full = cityDb[k]?.fullName ?? '';
                            return k.contains(query) || full.contains(query);
                          });
                        },
                        onSelected: (selection) {
                          cityController.text = selection;
                          onSearch();
                        },
                        fieldViewBuilder: (context, textController, fieldFocus, _) {
                          return TextField(
                            controller: textController,
                            focusNode: fieldFocus,
                            onSubmitted: (_) => onSearch(),
                            decoration: const InputDecoration(
                              hintText: '输入城市（如 上海）',
                              prefixIcon: Icon(Icons.search_rounded, size: 20),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 260),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final opt = options.elementAt(index);
                                    final full = cityDb[opt]?.fullName ?? opt;
                                    return ListTile(
                                      dense: true,
                                      title: Text(opt),
                                      subtitle: Text(full),
                                      onTap: () => onSelected(opt),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onSearch,
                      child: const Text('搜索'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: onClear,
                      child: const Text('清除'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 快捷城市 Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: kQuickCities.map((city) {
                      final selected = forecast.cityName == city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(city),
                          selected: selected,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => onQuickCityTap(city),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 核心预测数据卡
        Card.outlined(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${forecast.cityName} ${forecast.eventNameCn}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _LiveCountdownText(
                            eventTime: forecast.eventTime,
                            isTomorrow: isTomorrow,
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        forecast.eventTime,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _DataTile(
                label: forecast.runTimeName,
                value: forecast.runTimeStr,
                isMono: true,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _DataTile(
                label: '预报模型',
                value: forecast.modelDisplay,
                isMono: true,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _DataTile(
                label: '鲜艳度',
                value: forecast.quality.toStringAsFixed(2),
                badge: forecast.qualityTag,
                isMono: true,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _DataTile(
                label: '气溶胶 (AOD)',
                value: forecast.aod.toStringAsFixed(2),
                badge: forecast.aodTag,
                isMono: true,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _DataTile(
                label: '高 / 中 / 低云量',
                value: '${forecast.hcc}% / ${forecast.mcc}% / ${forecast.lcc}%',
                isMono: true,
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0.0 不烧', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        Text('0.4 微/小烧', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        Text('0.8 中烧', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        Text('1.0+ 大烧', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(cs.onSurface),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 摄影黄金窗口（Golden / 火烧云 / Blue Hour）
                    Row(
                      children: [
                        Expanded(
                          child: _PhotoWindowTile(
                            label: '黄金时刻',
                            timeRange: photoWindows.goldenHour,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _PhotoWindowTile(
                            label: '火烧云窗口',
                            timeRange: photoWindows.afterglowWindow,
                            highlighted: true,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _PhotoWindowTile(
                            label: '蓝调时刻',
                            timeRange: photoWindows.blueHour,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 出彩原因一句话解读
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 15,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              insightText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface,
                                height: 1.35,
                              ),
                            ),
                          ),
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

        // 三个功能入口按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onSwitchTab(1),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('详细预报'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onSwitchTab(2),
                icon: const Icon(Icons.cloud_outlined, size: 18),
                label: const Text('大气截面'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onSwitchTab(3),
                icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                label: const Text('悬日测试'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DataTile extends StatelessWidget {
  final String label;
  final String value;
  final String? badge;
  final bool isMono;

  const _DataTile({
    required this.label,
    required this.value,
    this.badge,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: isMono ? 'monospace' : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveCountdownText extends StatefulWidget {
  final String eventTime;
  final bool isTomorrow;

  const _LiveCountdownText({
    required this.eventTime,
    required this.isTomorrow,
  });

  @override
  State<_LiveCountdownText> createState() => _LiveCountdownTextState();
}

class _LiveCountdownTextState extends State<_LiveCountdownText> {
  Timer? _timer;
  late String _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = computeEventCountdown(widget.eventTime, widget.isTomorrow);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = computeEventCountdown(widget.eventTime, widget.isTomorrow);
      if (next != _countdown) {
        setState(() => _countdown = next);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _LiveCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventTime != widget.eventTime ||
        oldWidget.isTomorrow != widget.isTomorrow) {
      _countdown = computeEventCountdown(widget.eventTime, widget.isTomorrow);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      _countdown,
      style: theme.textTheme.labelSmall?.copyWith(
        fontFamily: 'monospace',
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _PhotoWindowTile extends StatelessWidget {
  final String label;
  final String timeRange;
  final bool highlighted;

  const _PhotoWindowTile({
    required this.label,
    required this.timeRange,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted
            ? cs.onSurface.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? cs.onSurface.withValues(alpha: 0.28) : cs.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: highlighted ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timeRange,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
