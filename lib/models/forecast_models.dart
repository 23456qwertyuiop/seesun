class CityInfo {
  final String fullName;
  final double lat;
  final double lon;
  double baseQ;
  double baseAod;
  int hcc;
  int mcc;
  int lcc;

  CityInfo({
    required this.fullName,
    required this.lat,
    required this.lon,
    required this.baseQ,
    required this.baseAod,
    required this.hcc,
    required this.mcc,
    required this.lcc,
  });
}

class ForecastResult {
  final String cityName;
  final String eventCode;
  final String eventNameCn;
  final String modelCode;
  final String modelDisplay;
  final String runTimeName;
  final String runTimeStr;
  String eventTime;
  final String azimuth;
  double quality;
  String qualityTag;
  double aod;
  String aodTag;
  int hcc;
  int mcc;
  int lcc;

  ForecastResult({
    required this.cityName,
    required this.eventCode,
    required this.eventNameCn,
    required this.modelCode,
    required this.modelDisplay,
    required this.runTimeName,
    required this.runTimeStr,
    required this.eventTime,
    required this.azimuth,
    required this.quality,
    required this.qualityTag,
    required this.aod,
    required this.aodTag,
    required this.hcc,
    required this.mcc,
    required this.lcc,
  });
}

class SunTimeResult {
  final String timeStr;
  final String azimuth;

  const SunTimeResult({required this.timeStr, required this.azimuth});
}

class ManhattanhengeResult {
  final String azimuthDisplay;
  final String dipDisplay;
  final String timeDisplay;

  const ManhattanhengeResult({
    required this.azimuthDisplay,
    required this.dipDisplay,
    required this.timeDisplay,
  });
}

class PhotoWindows {
  final String goldenHour;
  final String afterglowWindow;
  final String blueHour;

  const PhotoWindows({
    required this.goldenHour,
    required this.afterglowWindow,
    required this.blueHour,
  });
}

class DailyTrendPoint {
  final String dateLabel;
  final String eventTime;
  final double quality;
  final String qualityTag;
  final double aod;
  final int hcc;
  final int mcc;
  final int lcc;

  const DailyTrendPoint({
    required this.dateLabel,
    required this.eventTime,
    required this.quality,
    required this.qualityTag,
    required this.aod,
    required this.hcc,
    required this.mcc,
    required this.lcc,
  });
}

const Map<String, String> kEventLabels = {
  'rise_1': '今天日出',
  'set_1': '今天日落',
  'rise_2': '明天日出',
  'set_2': '明天日落',
};

const List<String> kQuickCities = [
  '上海',
  '北京',
  '杭州',
  '广州',
  '深圳',
  '成都',
  '武汉',
  '南京',
  '大理',
  '厦门',
];

final Map<String, CityInfo> cityDb = {
  '上海': CityInfo(fullName: '上海市-上海', lat: 31.2304, lon: 121.4737, baseQ: 1.18, baseAod: 0.22, hcc: 64, mcc: 28, lcc: 12),
  '北京': CityInfo(fullName: '北京市-北京', lat: 39.9042, lon: 116.4074, baseQ: 0.92, baseAod: 0.18, hcc: 52, mcc: 20, lcc: 8),
  '杭州': CityInfo(fullName: '浙江省-杭州', lat: 30.2741, lon: 120.1551, baseQ: 1.26, baseAod: 0.24, hcc: 68, mcc: 31, lcc: 14),
  '广州': CityInfo(fullName: '广东省-广州', lat: 23.1291, lon: 113.2644, baseQ: 0.65, baseAod: 0.31, hcc: 44, mcc: 35, lcc: 26),
  '深圳': CityInfo(fullName: '广东省-深圳', lat: 22.5431, lon: 114.0579, baseQ: 0.84, baseAod: 0.25, hcc: 55, mcc: 29, lcc: 19),
  '成都': CityInfo(fullName: '四川省-成都', lat: 30.5728, lon: 104.0668, baseQ: 0.36, baseAod: 0.42, hcc: 38, mcc: 48, lcc: 54),
  '武汉': CityInfo(fullName: '湖北省-武汉', lat: 30.5928, lon: 114.3055, baseQ: 0.78, baseAod: 0.29, hcc: 49, mcc: 26, lcc: 16),
  '南京': CityInfo(fullName: '江苏省-南京', lat: 32.0603, lon: 118.7969, baseQ: 1.05, baseAod: 0.23, hcc: 60, mcc: 24, lcc: 11),
  '大理': CityInfo(fullName: '云南省-大理', lat: 25.6065, lon: 100.2676, baseQ: 1.42, baseAod: 0.11, hcc: 72, mcc: 34, lcc: 9),
  '厦门': CityInfo(fullName: '福建省-厦门', lat: 24.4798, lon: 118.0894, baseQ: 0.96, baseAod: 0.19, hcc: 58, mcc: 22, lcc: 15),
  '青岛': CityInfo(fullName: '山东省-青岛', lat: 36.0671, lon: 120.3826, baseQ: 0.88, baseAod: 0.20, hcc: 51, mcc: 19, lcc: 10),
  '西安': CityInfo(fullName: '陕西省-西安', lat: 34.3416, lon: 108.9398, baseQ: 0.58, baseAod: 0.34, hcc: 42, mcc: 25, lcc: 18),
  '重庆': CityInfo(fullName: '重庆市-重庆', lat: 29.5630, lon: 106.5516, baseQ: 0.48, baseAod: 0.38, hcc: 45, mcc: 41, lcc: 42),
  '苏州': CityInfo(fullName: '江苏省-苏州', lat: 31.2989, lon: 120.5853, baseQ: 1.15, baseAod: 0.23, hcc: 63, mcc: 27, lcc: 13),
  '天津': CityInfo(fullName: '天津市-天津', lat: 39.0842, lon: 117.2009, baseQ: 0.86, baseAod: 0.21, hcc: 50, mcc: 22, lcc: 10),
  '长沙': CityInfo(fullName: '湖南省-长沙', lat: 28.2282, lon: 112.9388, baseQ: 0.72, baseAod: 0.30, hcc: 47, mcc: 30, lcc: 22),
  '昆明': CityInfo(fullName: '云南省-昆明', lat: 25.0389, lon: 102.7183, baseQ: 1.31, baseAod: 0.13, hcc: 69, mcc: 32, lcc: 11),
  '拉萨': CityInfo(fullName: '西藏自治区-拉萨', lat: 29.6525, lon: 91.1721, baseQ: 1.48, baseAod: 0.08, hcc: 75, mcc: 28, lcc: 6),
  '三亚': CityInfo(fullName: '海南省-三亚', lat: 18.2528, lon: 109.5119, baseQ: 1.09, baseAod: 0.14, hcc: 62, mcc: 25, lcc: 14),
  '哈尔滨': CityInfo(fullName: '黑龙江省-哈尔滨', lat: 45.8038, lon: 126.5349, baseQ: 0.82, baseAod: 0.19, hcc: 48, mcc: 21, lcc: 12),
};
