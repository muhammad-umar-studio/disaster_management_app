import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

class WeatherData {
  final String condition;
  final double tempF;
  final double tempC;
  final int humidity;
  final double windSpeedMph;
  final String windDirection;
  final int aqi;
  final String cityName;
  final String countryCode;
  final String iconCode;
  final String description;

  WeatherData({
    required this.condition,
    required this.tempF,
    required this.tempC,
    required this.humidity,
    required this.windSpeedMph,
    required this.windDirection,
    required this.aqi,
    required this.cityName,
    required this.countryCode,
    required this.iconCode,
    required this.description,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  bool get isFireWeather => tempF > 90 && humidity < 20 && windSpeedMph > 25;
  bool get isFloodRisk  => humidity > 80 || condition.toLowerCase().contains('rain');
  String get riskLabel {
    if (isFireWeather) return 'FIRE WEATHER — EXTREME';
    if (isFloodRisk)   return 'FLOOD RISK — ELEVATED';
    return 'CONDITIONS NORMAL';
  }
}

class WeatherService {
  static const _base = 'https://api.openweathermap.org/data/2.5';
  static const _key  = ApiKeys.openWeather;

  static Future<WeatherData?> fetchByCoords(double lat, double lon) async {
    try {
      final url = Uri.parse('$_base/weather?lat=$lat&lon=$lon&appid=$_key&units=imperial');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body);
      return WeatherData(
        condition:     j['weather'][0]['main'] ?? 'Unknown',
        description:   j['weather'][0]['description'] ?? '',
        iconCode:      j['weather'][0]['icon'] ?? '01d',
        tempF:         (j['main']['temp'] as num).toDouble(),
        tempC:         ((j['main']['temp'] as num) - 32) * 5 / 9,
        humidity:      (j['main']['humidity'] as num).toInt(),
        windSpeedMph:  (j['wind']['speed'] as num).toDouble(),
        windDirection: _degreesToDir((j['wind']['deg'] as num?)?.toDouble() ?? 0),
        aqi:           0, // filled separately
        cityName:      j['name'] ?? '',
        countryCode:   j['sys']['country'] ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<WeatherData?> fetchByCity(String city) async {
    try {
      final url = Uri.parse('$_base/weather?q=$city&appid=$_key&units=imperial');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body);
      return WeatherData(
        condition:    j['weather'][0]['main'] ?? 'Unknown',
        description:  j['weather'][0]['description'] ?? '',
        iconCode:     j['weather'][0]['icon'] ?? '01d',
        tempF:        (j['main']['temp'] as num).toDouble(),
        tempC:        ((j['main']['temp'] as num) - 32) * 5 / 9,
        humidity:     (j['main']['humidity'] as num).toInt(),
        windSpeedMph: (j['wind']['speed'] as num).toDouble(),
        windDirection: _degreesToDir((j['wind']['deg'] as num?)?.toDouble() ?? 0),
        aqi:          0,
        cityName:     j['name'] ?? city,
        countryCode:  j['sys']['country'] ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static String _degreesToDir(double deg) {
    const dirs = ['N','NE','E','SE','S','SW','W','NW'];
    return dirs[((deg / 45) % 8).round() % 8];
  }
}
