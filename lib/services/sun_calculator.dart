import 'dart:math' as math;
import '../models/forecast_models.dart';

SunTimeResult calcSunTime(double lat, double lon, bool isSunrise, int dayOffset) {
  final now = DateTime.now();
  final target = DateTime(now.year, now.month, now.day + dayOffset);
  final start = DateTime(target.year, 1, 0);
  final doy = target.difference(start).inDays;

  const rad = math.pi / 180.0;
  final decl = 23.45 * math.sin(rad * (360.0 / 365.0) * (284 + doy));
  final cosH = -math.tan(lat * rad) * math.tan(decl * rad);
  final clamped = cosH.clamp(-0.99, 0.99);
  final hourAngle = math.acos(clamped) / rad;

  final solarNoon = 12.0 - (lon - 120.0) / 15.0;
  final eventHour = isSunrise ? (solarNoon - hourAngle / 15.0) : (solarNoon + hourAngle / 15.0);

  final h = eventHour.floor();
  final m = ((eventHour - h) * 60).floor();
  final s = (((eventHour - h) * 60 - m) * 60).floor();

  String pad(int n) => math.max(0, n).toString().padLeft(2, '0');

  final cosAz = math.sin(decl * rad) / math.cos(lat * rad);
  final azBase = math.acos(cosAz.clamp(-1.0, 1.0)) / rad;
  final azimuth = isSunrise ? azBase : (360.0 - azBase);

  return SunTimeResult(
    timeStr: '${pad(h)}:${pad(m)}:${pad(s)}',
    azimuth: azimuth.toStringAsFixed(1),
  );
}

String getQualityLabel(double q) {
  if (q < 0.2) return '不烧';
  if (q < 0.4) return '微烧';
  if (q < 0.75) return '小烧';
  if (q < 1.05) return '中烧';
  if (q < 1.45) return '大烧';
  return '世纪大烧';
}

String getAodLabel(double aod) {
  if (aod <= 0.18) return '极通透';
  if (aod <= 0.28) return '通透';
  if (aod <= 0.40) return '轻度浑浊';
  return '浑浊';
}

String normalizeCityName(String? rawCity) {
  final cleaned = (rawCity ?? '上海')
      .replaceFirst(RegExp(r'^.*-'), '')
      .replaceAll(RegExp(r'市|省|自治区'), '')
      .trim();
  return cleaned.isEmpty ? '上海' : cleaned;
}

ForecastResult computeForecast(String? rawCity, String eventCode, String modelCode) {
  final cleanName = normalizeCityName(rawCity);
  CityInfo? cityInfo = cityDb[cleanName];

  if (cityInfo == null) {
    int hash = 0;
    for (int i = 0; i < cleanName.length; i++) {
      hash = (hash * 31 + cleanName.codeUnitAt(i)) % 1000;
    }
    cityInfo = CityInfo(
      fullName: cleanName,
      lat: (25 + (hash % 15)).toDouble(),
      lon: (105 + (hash % 18)).toDouble(),
      baseQ: double.parse((0.25 + (hash % 120) / 100.0).toStringAsFixed(2)),
      baseAod: double.parse((0.14 + (hash % 30) / 100.0).toStringAsFixed(2)),
      hcc: 35 + (hash % 45),
      mcc: 18 + (hash % 35),
      lcc: 10 + (hash % 30),
    );
  }

  final isRise = eventCode.startsWith('rise');
  final dayOffset = eventCode.endsWith('2') ? 1 : 0;
  final sun = calcSunTime(cityInfo.lat, cityInfo.lon, isRise, dayOffset);

  const eventFactors = {
    'rise_1': -0.14,
    'set_1': 0.0,
    'rise_2': -0.06,
    'set_2': 0.11,
  };
  final eventFactor = eventFactors[eventCode] ?? 0.0;
  final modelFactor = modelCode == 'GFS' ? -0.07 : 0.0;

  final quality = math.max(
    0.05,
    double.parse((cityInfo.baseQ + eventFactor + modelFactor).toStringAsFixed(2)),
  );
  final aod = math.max(
    0.08,
    double.parse((cityInfo.baseAod + (modelCode == 'GFS' ? 0.02 : 0.0)).toStringAsFixed(2)),
  );
  final hcc = (cityInfo.hcc + eventFactor * 40).round().clamp(5, 98);
  final mcc = (cityInfo.mcc + (modelCode == 'GFS' ? 5 : 0)).round().clamp(5, 95);
  final lcc = cityInfo.lcc.clamp(3, 95);

  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final runHour = modelCode == 'EC' ? '08:00 CST' : '07:30 CST';

  return ForecastResult(
    cityName: cleanName,
    eventCode: eventCode,
    eventNameCn: kEventLabels[eventCode] ?? '今天日落',
    modelCode: modelCode,
    modelDisplay: modelCode == 'EC' ? 'ECMWF + CAMS' : 'NCEP-GFS + CAMS',
    runTimeName: '起报时次',
    runTimeStr: '$dateStr $runHour',
    eventTime: sun.timeStr,
    azimuth: sun.azimuth,
    quality: quality,
    qualityTag: getQualityLabel(quality),
    aod: aod,
    aodTag: getAodLabel(aod),
    hcc: hcc,
    mcc: mcc,
    lcc: lcc,
  );
}

({String key, CityInfo info}) findNearestCity(double lat, double lon) {
  String bestKey = '上海';
  double minDist = double.infinity;
  const rad = math.pi / 180.0;

  for (final entry in cityDb.entries) {
    final dLat = (entry.value.lat - lat) * rad;
    final dLon = (entry.value.lon - lon) * rad;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat * rad) *
            math.cos(entry.value.lat * rad) *
            math.pow(math.sin(dLon / 2), 2);
    final distKm = 6371.0 * 2.0 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    if (distKm < minDist) {
      minDist = distKm;
      bestKey = entry.key;
    }
  }
  return (key: bestKey, info: cityDb[bestKey]!);
}

ManhattanhengeResult calculateManhattanhenge({
  required double lon,
  required double lat,
  required double heightMeters,
  required bool isSunrise,
}) {
  final sun = calcSunTime(lat, lon, isSunrise, 0);
  final dip = -(0.53 + 0.0347 * math.sqrt(math.max(0.0, heightMeters)));
  final azNum = double.tryParse(sun.azimuth) ?? 0.0;
  final offsetAngle = isSunrise ? (azNum - 90.0) : (270.0 - azNum);
  final dirText = isSunrise
      ? '东偏南 ${offsetAngle.toStringAsFixed(2)}°'
      : '西偏南 ${offsetAngle.toStringAsFixed(2)}°';

  return ManhattanhengeResult(
    azimuthDisplay: '${sun.azimuth}° ($dirText)',
    dipDisplay: '${dip.toStringAsFixed(2)}°',
    timeDisplay: sun.timeStr,
  );
}
