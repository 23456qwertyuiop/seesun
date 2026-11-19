import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/forecast_models.dart';
import 'location_helper.dart';
import 'sun_calculator.dart';

class DetectedLocation {
  final String cityName;
  final String statusText;
  final double lat;
  final double lon;

  const DetectedLocation({
    required this.cityName,
    required this.statusText,
    required this.lat,
    required this.lon,
  });
}

class MeteoService {
  static Future<ForecastResult?> fetchLiveMeteoAndAod({
    required ForecastResult baseRes,
    required String eventCode,
    required String modelCode,
  }) async {
    final cleanName = baseRes.cityName;

    try {
      if (!cityDb.containsKey(cleanName)) {
        final geoUri = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cleanName)}&count=1&language=zh&format=json',
        );
        final geoResp = await http.get(geoUri).timeout(const Duration(seconds: 8));
        if (geoResp.statusCode == 200) {
          final geoData = jsonDecode(geoResp.body) as Map<String, dynamic>;
          final results = geoData['results'] as List<dynamic>?;
          if (results != null && results.isNotEmpty) {
            final g = results[0] as Map<String, dynamic>;
            final admin1 = (g['admin1'] as String?) ?? '';
            final name = (g['name'] as String?) ?? cleanName;
            final full = '$admin1-$name'.replaceFirst(RegExp(r'^-'), '');
            cityDb[cleanName] = CityInfo(
              fullName: full,
              lat: double.parse(((g['latitude'] as num).toDouble()).toStringAsFixed(4)),
              lon: double.parse(((g['longitude'] as num).toDouble()).toStringAsFixed(4)),
              baseQ: 0.75,
              baseAod: 0.22,
              hcc: 50,
              mcc: 25,
              lcc: 15,
            );
          }
        }
      }

      final cityInfo = cityDb[cleanName];
      final lat = cityInfo?.lat ?? 31.2304;
      final lon = cityInfo?.lon ?? 121.4737;
      final modelParam = modelCode == 'EC' ? 'ecmwf_ifs025' : 'gfs_seamless';

      final meteoUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=cloud_cover_low,cloud_cover_mid,cloud_cover_high&daily=sunrise,sunset&timezone=auto&forecast_days=2&models=$modelParam',
      );
      final aodUri = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&hourly=aerosol_optical_depth&timezone=auto&forecast_days=2',
      );

      final responses = await Future.wait([
        http.get(meteoUri).timeout(const Duration(seconds: 10)),
        http.get(aodUri).timeout(const Duration(seconds: 10)).catchError(
              (_) => http.Response('', 500),
            ),
      ]);

      final meteoResp = responses[0];
      final aodResp = responses[1];

      if (meteoResp.statusCode == 200) {
        final meteo = jsonDecode(meteoResp.body) as Map<String, dynamic>;
        final aodData = aodResp.statusCode == 200
            ? jsonDecode(aodResp.body) as Map<String, dynamic>
            : null;

        final isRise = eventCode.startsWith('rise');
        final dayIdx = eventCode.endsWith('2') ? 1 : 0;

        int targetHour = isRise ? 6 : 17;
        final daily = meteo['daily'] as Map<String, dynamic>?;
        if (daily != null) {
          final isoList = (isRise ? daily['sunrise'] : daily['sunset']) as List<dynamic>?;
          if (isoList != null && dayIdx < isoList.length) {
            final iso = isoList[dayIdx]?.toString() ?? '';
            final parts = iso.split('T');
            if (parts.length > 1) {
              final timePart = parts[1];
              targetHour = int.tryParse(timePart.split(':')[0]) ?? targetHour;
              baseRes.eventTime = '$timePart:00';
            }
          }
        }

        final hourIdx = math.min(47, dayIdx * 24 + targetHour);
        final hourly = meteo['hourly'] as Map<String, dynamic>?;
        final aodHourly = aodData?['hourly'] as Map<String, dynamic>?;

        int readCloud(String key, int fallback) {
          final list = hourly?[key] as List<dynamic>?;
          if (list != null && hourIdx < list.length && list[hourIdx] != null) {
            return (list[hourIdx] as num).round();
          }
          return fallback;
        }

        final hcc = readCloud('cloud_cover_high', baseRes.hcc);
        final mcc = readCloud('cloud_cover_mid', baseRes.mcc);
        final lcc = readCloud('cloud_cover_low', baseRes.lcc);

        double aodVal = baseRes.aod;
        final aodList = aodHourly?['aerosol_optical_depth'] as List<dynamic>?;
        if (aodList != null && hourIdx < aodList.length && aodList[hourIdx] != null) {
          aodVal = double.parse((aodList[hourIdx] as num).toDouble().toStringAsFixed(2));
        }

        final carrierScore = (hcc * 0.0125) + (mcc * 0.0085);
        final blockPenalty = (lcc * 0.009) + math.max(0.0, (aodVal - 0.15) * 0.95);
        final rawVividness = double.parse(
          (carrierScore - blockPenalty + 0.28).clamp(0.05, 1.65).toStringAsFixed(2),
        );

        baseRes.hcc = hcc;
        baseRes.mcc = mcc;
        baseRes.lcc = lcc;
        baseRes.aod = aodVal;
        baseRes.aodTag = getAodLabel(aodVal);
        baseRes.quality = rawVividness;
        baseRes.qualityTag = getQualityLabel(rawVividness);

        if (cityDb.containsKey(cleanName)) {
          cityDb[cleanName]!.baseQ = rawVividness;
          cityDb[cleanName]!.baseAod = aodVal;
          cityDb[cleanName]!.hcc = hcc;
          cityDb[cleanName]!.mcc = mcc;
          cityDb[cleanName]!.lcc = lcc;
        }

        return baseRes;
      }
    } catch (_) {}

    return null;
  }

  static Future<List<DailyTrendPoint>?> fetchWeeklyTrend({
    required String cityName,
    required String modelCode,
    required bool isSunrise,
  }) async {
    final cleanName = normalizeCityName(cityName);
    final cityInfo = cityDb[cleanName];
    final lat = cityInfo?.lat ?? 31.2304;
    final lon = cityInfo?.lon ?? 121.4737;
    final modelParam = modelCode == 'EC' ? 'ecmwf_ifs025' : 'gfs_seamless';

    try {
      final meteoUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=cloud_cover_low,cloud_cover_mid,cloud_cover_high&daily=sunrise,sunset&timezone=auto&forecast_days=7&models=$modelParam',
      );
      final aodUri = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&hourly=aerosol_optical_depth&timezone=auto&forecast_days=7',
      );

      final responses = await Future.wait([
        http.get(meteoUri).timeout(const Duration(seconds: 10)),
        http.get(aodUri).timeout(const Duration(seconds: 10)).catchError(
              (_) => http.Response('', 500),
            ),
      ]);

      final meteoResp = responses[0];
      final aodResp = responses[1];

      if (meteoResp.statusCode == 200) {
        final meteo = jsonDecode(meteoResp.body) as Map<String, dynamic>;
        final aodData = aodResp.statusCode == 200
            ? jsonDecode(aodResp.body) as Map<String, dynamic>
            : null;

        final daily = meteo['daily'] as Map<String, dynamic>?;
        final hourly = meteo['hourly'] as Map<String, dynamic>?;
        final aodHourly = aodData?['hourly'] as Map<String, dynamic>?;
        final isoList = daily?[isSunrise ? 'sunrise' : 'sunset'] as List<dynamic>?;

        final now = DateTime.now();
        const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

        int readCloud(String key, int idx, int fallback) {
          final list = hourly?[key] as List<dynamic>?;
          if (list != null && idx < list.length && list[idx] != null) {
            return (list[idx] as num).round();
          }
          return fallback;
        }

        final aodList = aodHourly?['aerosol_optical_depth'] as List<dynamic>?;
        final points = <DailyTrendPoint>[];

        for (int day = 0; day < 7; day++) {
          final targetDate = now.add(Duration(days: day));
          final dateLabel = day == 0
              ? '今天'
              : (day == 1 ? '明天' : weekdays[targetDate.weekday - 1]);

          int targetHour = isSunrise ? 6 : 17;
          String timeStr = isSunrise ? '06:00' : '17:30';
          if (isoList != null && day < isoList.length) {
            final iso = isoList[day]?.toString() ?? '';
            final parts = iso.split('T');
            if (parts.length > 1) {
              timeStr = parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
              targetHour = int.tryParse(timeStr.split(':')[0]) ?? targetHour;
            }
          }

          final hourIdx = math.min(167, day * 24 + targetHour);
          final hcc = readCloud('cloud_cover_high', hourIdx, 50);
          final mcc = readCloud('cloud_cover_mid', hourIdx, 25);
          final lcc = readCloud('cloud_cover_low', hourIdx, 15);

          double aodVal = 0.22;
          if (aodList != null && hourIdx < aodList.length && aodList[hourIdx] != null) {
            aodVal = double.parse((aodList[hourIdx] as num).toDouble().toStringAsFixed(2));
          }

          final carrierScore = (hcc * 0.0125) + (mcc * 0.0085);
          final blockPenalty = (lcc * 0.009) + math.max(0.0, (aodVal - 0.15) * 0.95);
          final quality = double.parse(
            (carrierScore - blockPenalty + 0.28).clamp(0.05, 1.65).toStringAsFixed(2),
          );

          points.add(
            DailyTrendPoint(
              dateLabel: dateLabel,
              eventTime: timeStr,
              quality: quality,
              qualityTag: getQualityLabel(quality),
              aod: aodVal,
              hcc: hcc,
              mcc: mcc,
              lcc: lcc,
            ),
          );
        }
        return points;
      }
    } catch (_) {}

    return null;
  }

  static Future<DetectedLocation?> autoDetectLocation({required bool isManual}) async {
    final pos = await getBrowserPosition(isManual: isManual);
    if (pos != null) {
      return await _reverseGeocode(pos.lat, pos.lon, 'GPS定位');
    }
    return await _fallbackIpLocation();
  }

  static DetectedLocation _applyDetectedLocation(
    double lat,
    double lon,
    String? rawCityName,
    String? rawDistrictName,
    String sourceLabel,
  ) {
    final nearest = findNearestCity(lat, lon);
    var cleanCity = (rawCityName ?? '')
        .replaceAll(RegExp(r'市|省|特别行政区|壮族自治区|回族自治区|维吾尔自治区|自治区'), '')
        .trim();
    if (cleanCity.isEmpty) cleanCity = nearest.key;

    final baseRef = cityDb[cleanCity] ?? nearest.info;
    cityDb[cleanCity] = CityInfo(
      fullName: (rawDistrictName != null && rawDistrictName.isNotEmpty)
          ? '$cleanCity-$rawDistrictName'
          : baseRef.fullName,
      lat: double.parse(lat.toStringAsFixed(4)),
      lon: double.parse(lon.toStringAsFixed(4)),
      baseQ: baseRef.baseQ,
      baseAod: baseRef.baseAod,
      hcc: baseRef.hcc,
      mcc: baseRef.mcc,
      lcc: baseRef.lcc,
    );

    final locDetail = (rawDistrictName != null && rawDistrictName.isNotEmpty)
        ? '$cleanCity·$rawDistrictName'
        : cleanCity;

    return DetectedLocation(
      cityName: cleanCity,
      statusText: '$sourceLabel: $locDetail (${lat.toStringAsFixed(2)}°N, ${lon.toStringAsFixed(2)}°E)',
      lat: lat,
      lon: lon,
    );
  }

  static Future<DetectedLocation> _reverseGeocode(
    double lat,
    double lon,
    String sourceLabel,
  ) async {
    final nearest = findNearestCity(lat, lon);
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=zh',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final city = (data['city'] as String?)?.isNotEmpty == true
            ? data['city'] as String
            : ((data['principalSubdivision'] as String?) ?? nearest.key);
        final locality = data['locality'] as String?;
        final district = (locality != null && locality != city) ? locality : '';
        return _applyDetectedLocation(lat, lon, city, district, sourceLabel);
      }
    } catch (_) {}

    return _applyDetectedLocation(lat, lon, nearest.key, '', sourceLabel);
  }

  static Future<DetectedLocation?> _fallbackIpLocation() async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?localityLanguage=zh',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final lat = data['latitude'];
        final lon = data['longitude'];
        if (lat is num && lon is num) {
          final city = (data['city'] as String?)?.isNotEmpty == true
              ? data['city'] as String
              : ((data['principalSubdivision'] as String?) ?? '上海');
          final locality = data['locality'] as String?;
          final district = (locality != null && locality != city) ? locality : '';
          return _applyDetectedLocation(
            lat.toDouble(),
            lon.toDouble(),
            city,
            district,
            'IP定位',
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
