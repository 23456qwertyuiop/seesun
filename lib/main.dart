import 'package:flutter/material.dart';
import 'models/forecast_models.dart';
import 'services/meteo_service.dart';
import 'services/sun_calculator.dart';
import 'theme/seesun_theme.dart';
import 'widgets/detailed_tab.dart';
import 'widgets/home_tab.dart';
import 'widgets/lab_tab.dart';
import 'widgets/liquid_bottom_dock.dart';
import 'widgets/xsec_tab.dart';

void main() {
  runApp(const SeesunApp());
}

class SeesunApp extends StatefulWidget {
  const SeesunApp({super.key});

  @override
  State<SeesunApp> createState() => _SeesunAppState();
}

class _SeesunAppState extends State<SeesunApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final fg = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final surfaceContainer = isDark ? const Color(0xFF121214) : const Color(0xFFF5F5F7);
    final surfaceHighest = isDark ? const Color(0xFF1E1E22) : const Color(0xFFE8E8ED);
    final outline = isDark ? const Color(0xFF2C2C32) : const Color(0xFFDCDCE2);
    final muted = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: fg,
      onPrimary: bg,
      secondary: fg,
      onSecondary: bg,
      error: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F),
      onError: bg,
      surface: bg,
      onSurface: fg,
      surfaceContainerLowest: bg,
      surfaceContainerLow: surfaceContainer,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceHighest,
      surfaceContainerHighest: surfaceHighest,
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF0A0A0C) : const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outline),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        indicatorColor: isDark ? const Color(0xFF232328) : const Color(0xFFEAEAF0),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? fg : muted,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? fg : muted,
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'seesun',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: SeesunHomePage(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          });
        },
      ),
    );
  }
}

class SeesunHomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SeesunHomePage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<SeesunHomePage> createState() => _SeesunHomePageState();
}

class _SeesunHomePageState extends State<SeesunHomePage> {
  int _currentTab = 0;

  bool _isLocating = true;
  String _geoStatusText = '正在自动定位...';

  String _currentCity = '上海';
  String _selectedEvent = 'set_1';
  String _selectedModel = 'EC';

  late ForecastResult _forecast;
  int _activeFetchId = 0;

  final TextEditingController _cityController = TextEditingController();
  final FocusNode _cityFocusNode = FocusNode();

  final TextEditingController _lonController = TextEditingController(text: '121.4737');
  final TextEditingController _latController = TextEditingController(text: '31.2304');
  final TextEditingController _heightController = TextEditingController(text: '25');
  String _labEvent = 'sunset';
  late ManhattanhengeResult _labResult;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _forecast = computeForecast(_currentCity, _selectedEvent, _selectedModel);
    _labResult = calculateManhattanhenge(
      lon: 121.4737,
      lat: 31.2304,
      heightMeters: 25,
      isSunrise: false,
    );
    _refreshForecast();
    _autoDetectLocation(isManual: false);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _cityFocusNode.dispose();
    _lonController.dispose();
    _latController.dispose();
    _heightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshForecast({String? overrideCity}) {
    final queryCity = (overrideCity ?? _cityController.text.trim()).isNotEmpty
        ? (overrideCity ?? _cityController.text.trim())
        : _currentCity;

    final res = computeForecast(queryCity, _selectedEvent, _selectedModel);
    setState(() {
      _currentCity = res.cityName;
      _forecast = res;
      final info = cityDb[res.cityName];
      if (info != null) {
        _lonController.text = info.lon.toString();
        _latController.text = info.lat.toString();
      }
      _recalculateLab();
    });

    final fetchId = ++_activeFetchId;
    MeteoService.fetchLiveMeteoAndAod(
      baseRes: res,
      eventCode: _selectedEvent,
      modelCode: _selectedModel,
    ).then((liveRes) {
      if (!mounted || fetchId != _activeFetchId || liveRes == null) return;
      setState(() {
        _forecast = liveRes;
        final info = cityDb[liveRes.cityName];
        if (info != null) {
          _lonController.text = info.lon.toString();
          _latController.text = info.lat.toString();
        }
        _recalculateLab();
      });
    });
  }

  Future<void> _autoDetectLocation({required bool isManual}) async {
    setState(() {
      _isLocating = true;
      _geoStatusText = '正在定位...';
    });

    final detected = await MeteoService.autoDetectLocation(isManual: isManual);
    if (!mounted) return;

    if (detected != null) {
      _cityController.text = detected.cityName;
      _lonController.text = detected.lon.toStringAsFixed(4);
      _latController.text = detected.lat.toStringAsFixed(4);
      setState(() {
        _isLocating = false;
        _geoStatusText = detected.statusText;
        _currentCity = detected.cityName;
      });
      _refreshForecast(overrideCity: detected.cityName);
    } else {
      setState(() {
        _isLocating = false;
        _geoStatusText = '默认位置: 上海';
      });
    }
  }

  void _recalculateLab() {
    final lon = double.tryParse(_lonController.text) ?? 121.4737;
    final lat = double.tryParse(_latController.text) ?? 31.2304;
    final h = double.tryParse(_heightController.text) ?? 25.0;
    _labResult = calculateManhattanhenge(
      lon: lon,
      lat: lat,
      heightMeters: h,
      isSunrise: _labEvent == 'sunrise',
    );
  }

  void _switchTab(int index) {
    setState(() {
      _currentTab = index;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dockColors = widget.isDark ? SeesunColors.dark : SeesunColors.light;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        centerTitle: false,
        title: GestureDetector(
          onTap: () => _switchTab(0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  'logo.JPG',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'seesun',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: widget.onToggleTheme,
              icon: Icon(
                widget.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 16,
              ),
              label: Text(widget.isDark ? '纯黑' : '纯白', style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          14,
          14,
          14,
          MediaQuery.of(context).padding.bottom + 98,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentTab),
                child: switch (_currentTab) {
                  0 => HomeTab(
                      isLocating: _isLocating,
                      geoStatusText: _geoStatusText,
                      selectedEvent: _selectedEvent,
                      selectedModel: _selectedModel,
                      cityController: _cityController,
                      cityFocusNode: _cityFocusNode,
                      forecast: _forecast,
                      onLocate: () => _autoDetectLocation(isManual: true),
                      onEventChanged: (ev) {
                        _selectedEvent = ev;
                        _refreshForecast();
                      },
                      onModelChanged: (m) {
                        _selectedModel = m;
                        _refreshForecast();
                      },
                      onSearch: () => _refreshForecast(),
                      onClear: () {
                        _cityController.clear();
                        _cityFocusNode.requestFocus();
                      },
                      onQuickCityTap: (city) {
                        _cityController.text = city;
                        _refreshForecast(overrideCity: city);
                      },
                      onSwitchTab: _switchTab,
                    ),
                  1 => DetailedTab(
                      forecast: _forecast,
                      onBack: () => _switchTab(0),
                      onSelectEvent: (ev) {
                        _selectedEvent = ev;
                        _refreshForecast();
                      },
                    ),
                  2 => XSecTab(
                      forecast: _forecast,
                    ),
                  _ => LabTab(
                      lonController: _lonController,
                      latController: _latController,
                      heightController: _heightController,
                      labEvent: _labEvent,
                      result: _labResult,
                      onLocate: () => _autoDetectLocation(isManual: true),
                      onEventChanged: (ev) {
                        setState(() {
                          _labEvent = ev;
                          _recalculateLab();
                        });
                      },
                      onCalculate: () {
                        setState(() {
                          _recalculateLab();
                        });
                      },
                    ),
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: LiquidBottomDock(
        colors: dockColors,
        currentIndex: _currentTab,
        onChanged: _switchTab,
        items: const [
          LiquidDockItemData(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: '主页',
          ),
          LiquidDockItemData(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics_rounded,
            label: '详细预报',
          ),
          LiquidDockItemData(
            icon: Icons.cloud_outlined,
            activeIcon: Icons.cloud_rounded,
            label: '大气截面',
          ),
          LiquidDockItemData(
            icon: Icons.wb_sunny_outlined,
            activeIcon: Icons.wb_sunny_rounded,
            label: '悬日测试',
          ),
        ],
      ),
    );
  }
}
