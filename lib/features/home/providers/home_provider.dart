import 'package:flutter/material.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/services/location_service.dart';

class HomeProvider extends ChangeNotifier {
  // Weather
  WeatherData? _weather;
  WeatherData? get weather => _weather;

  // Location
  LocationData? _location;
  LocationData? get location => _location;

  // Derived getters with fallbacks
  double  get windSpeed        => _weather?.windSpeedMph     ?? 0;
  String  get riskLevel        => _computeRiskLevel();
  int     get aiSafetyScore    => _computeSafetyScore();
  String  get systemStatus     => _weather != null ? 'SYSTEM ACTIVE' : 'INITIALIZING';
  bool    get isLoading        => _loading;
  String  get weatherCondition => _weather?.condition        ?? 'Loading...';
  double  get temperature      => _weather?.tempF            ?? 0;
  int     get humidity         => _weather?.humidity         ?? 0;
  String  get locationName     => _location != null ? '${_location!.city}, ${_location!.country}' : 'Locating...';
  bool    get hasRealData      => _weather != null;
  bool    get _loading         => _isLoading;

  bool _isLoading = false;
  String? _error;
  String? get error => _error;

  Color get riskLevelColor {
    switch (riskLevel) {
      case 'CRITICAL':  return const Color(0xFFFF3B30);
      case 'HIGH':      return const Color(0xFFFF9F0A);
      case 'ELEVATED':  return const Color(0xFFFFD60A);
      case 'LOW':       return const Color(0xFF30D158);
      case 'SECURE':    return const Color(0xFF30D158);
      default:          return const Color(0xFF6B7A99);
    }
  }

  Color get safetyScoreColor {
    final s = aiSafetyScore;
    if (s >= 80) return const Color(0xFF30D158);
    if (s >= 60) return const Color(0xFFFFD60A);
    if (s >= 40) return const Color(0xFFFF9F0A);
    return const Color(0xFFFF3B30);
  }

  HomeProvider() { _init(); }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Get location first
    _location = await LocationService.getCurrentLocation();
    notifyListeners();

    // Then fetch weather
    await _fetchWeather();

    _isLoading = false;
    notifyListeners();

    // Refresh every 10 minutes
    _scheduleRefresh();
  }

  Future<void> _fetchWeather() async {
    try {
      if (_location != null) {
        _weather = await WeatherService.fetchByCoords(_location!.latitude, _location!.longitude);
      }
      _error = null;
    } catch (e) {
      _error = 'Weather fetch failed';
    }
    notifyListeners();
  }

  void _scheduleRefresh() {
    Future.delayed(const Duration(minutes: 10), () {
      _fetchWeather();
      _scheduleRefresh();
    });
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    _location = await LocationService.getCurrentLocation();
    await _fetchWeather();
    _isLoading = false;
    notifyListeners();
  }

  String _computeRiskLevel() {
    if (_weather == null) return 'UNKNOWN';
    if (_weather!.isFireWeather) return 'CRITICAL';
    if (temperature > 95 || humidity < 20) return 'HIGH';
    if (_weather!.isFloodRisk)  return 'ELEVATED';
    if (temperature > 85 || windSpeed > 30) return 'ELEVATED';
    return 'LOW';
  }

  int _computeSafetyScore() {
    if (_weather == null) return 85;
    int score = 100;
    if (temperature > 100) score -= 25;
    else if (temperature > 90) score -= 10;
    if (humidity < 15) score -= 20;
    else if (humidity < 25) score -= 10;
    if (windSpeed > 40) score -= 20;
    else if (windSpeed > 25) score -= 10;
    if (_weather!.isFloodRisk) score -= 15;
    return score.clamp(0, 100);
  }
}
