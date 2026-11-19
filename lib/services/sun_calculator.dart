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

int _parseEventSeconds(String eventTime) {
  final parts = eventTime.split(':');
  final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 17) : 17;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  final s = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
  return h * 3600 + m * 60 + s;
}

String _formatHhMmFromMinutes(int totalMinutes) {
  final wrapped = ((totalMinutes % 1440) + 1440) % 1440;
  final h = wrapped ~/ 60;
  final m = wrapped % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

PhotoWindows computePhotoWindows(String eventTime, bool isSunrise) {
  final totalSec = _parseEventSeconds(eventTime);
  final centerMin = (totalSec / 60).round();

  String range(int startDelta, int endDelta) {
    return '${_formatHhMmFromMinutes(centerMin + startDelta)}-${_formatHhMmFromMinutes(centerMin + endDelta)}';
  }

  if (isSunrise) {
    return PhotoWindows(
      goldenHour: range(0, 40),
      afterglowWindow: range(-25, 5),
      blueHour: range(-45, -20),
    );
  } else {
    return PhotoWindows(
      goldenHour: range(-40, 0),
      afterglowWindow: range(-5, 25),
      blueHour: range(20, 45),
    );
  }
}

String computeEventCountdown(String eventTime, bool isTomorrow) {
  final now = DateTime.now();
  final parts = eventTime.split(':');
  final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 17) : 17;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  final s = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

  final target = DateTime(
    now.year,
    now.month,
    now.day + (isTomorrow ? 1 : 0),
    h,
    m,
    s,
  );
  final diff = target.difference(now);

  String fmt(Duration d) {
    final abs = d.abs();
    final hh = abs.inHours.toString().padLeft(2, '0');
    final mm = (abs.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (abs.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  if (diff.isNegative) {
    return '已过 ${fmt(diff)}';
  }
  return '还有 ${fmt(diff)}';
}

String generateForecastInsight(ForecastResult res) {
  if (res.lcc >= 45) {
    return '低云较厚（${res.lcc}%），容易遮挡地平线附近的直射阳光，出彩概率偏低。';
  }
  if (res.aod > 0.38) {
    return '气溶胶偏高（AOD ${res.aod.toStringAsFixed(2)}），低空略浑浊，光线穿透力减弱。';
  }
  if (res.hcc + res.mcc < 25) {
    return '高/中云偏少（合计 ${res.hcc + res.mcc}%），天空较晴朗，缺少云层作为火烧云反射载体。';
  }
  if (res.quality >= 1.05) {
    return '高/中云（${res.hcc}%/${res.mcc}%）搭配通透低空，光线极易穿透漫反射，建议提前蹲守！';
  }
  if (res.quality >= 0.75) {
    return '云层分布较理想且大气通透，${res.eventNameCn}前后有机会看到明显霞光。';
  }
  return '具备一定高/中云载体，但低云或通透度略有干扰，可能会出现局部微霞。';
}

List<DailyTrendPoint> computeFallbackWeeklyTrend(
  String cityName,
  String modelCode,
  bool isSunrise,
) {
  final cleanName = normalizeCityName(cityName);
  final base = computeForecast(
    cleanName,
    isSunrise ? 'rise_1' : 'set_1',
    modelCode,
  );
  final cityInfo = cityDb[cleanName];
  final lat = cityInfo?.lat ?? 31.2304;
  final lon = cityInfo?.lon ?? 121.4737;

  final now = DateTime.now();
  const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  return List.generate(7, (day) {
    final targetDate = now.add(Duration(days: day));
    final label = day == 0
        ? '今天'
        : (day == 1 ? '明天' : weekdays[targetDate.weekday - 1]);
    final sun = calcSunTime(lat, lon, isSunrise, day);

    final wave = ((day * 37 + cleanName.hashCode) % 5 - 2) * 0.08;
    final q = double.parse((base.quality + wave).clamp(0.10, 1.55).toStringAsFixed(2));
    final aod = double.parse((base.aod + wave * 0.15).clamp(0.08, 0.55).toStringAsFixed(2));
    final hcc = (base.hcc + (day * 7 % 15) - 7).clamp(8, 95);
    final mcc = (base.mcc + (day * 5 % 12) - 6).clamp(5, 90);
    final lcc = (base.lcc + (day * 3 % 10) - 5).clamp(3, 85);

    return DailyTrendPoint(
      dateLabel: label,
      eventTime: sun.timeStr.substring(0, 5),
      quality: q,
      qualityTag: getQualityLabel(q),
      aod: aod,
      hcc: hcc,
      mcc: mcc,
      lcc: lcc,
    );
  });
}
