import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

/// Real disaster alert fetched from live APIs
class LiveAlert {
  final String id;
  final String title;
  final String type;       // EARTHQUAKE | STORM | FLOOD | HEAT | WIND
  final String severity;   // CRITICAL | HIGH | MEDIUM | LOW
  final String location;
  final String description;
  final DateTime time;
  final double? magnitude; // for earthquakes
  final double? lat;
  final double? lng;
  bool isActive;

  LiveAlert({
    required this.id,        required this.title,
    required this.type,      required this.severity,
    required this.location,  required this.description,
    required this.time,      this.magnitude,
    this.lat,                this.lng,
    this.isActive = true,
  });
}

class AlertService {
  static const _usgsUrl =
      'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson';

  /// Fetch real alerts for a given lat/lng
  static Future<List<LiveAlert>> fetchAlerts({
    required double lat,
    required double lng,
    double? tempC,
    double? windKph,
    String? weatherMain,
    String? weatherDesc,
    double? humidity,
  }) async {
    final alerts = <LiveAlert>[];

    // 1. Real earthquakes from USGS (within ~500 km)
    try {
      final eq = await _fetchEarthquakes(lat, lng);
      alerts.addAll(eq);
    } catch (e) {
      debugPrint('[Alerts] USGS fetch error: $e');
    }

    // 2. Weather-derived alerts from OpenWeatherMap data
    if (weatherMain != null) {
      alerts.addAll(_buildWeatherAlerts(
        lat: lat, lng: lng,
        tempC: tempC, windKph: windKph,
        weatherMain: weatherMain, weatherDesc: weatherDesc,
        humidity: humidity,
      ));
    }

    // 3. Always fetch live weather to build alerts even if called standalone
    if (weatherMain == null) {
      try {
        final weatherAlerts = await _fetchWeatherAlerts(lat, lng);
        alerts.addAll(weatherAlerts);
      } catch (e) {
        debugPrint('[Alerts] Weather alert error: $e');
      }
    }

    // Sort by severity then time
    alerts.sort((a, b) {
      final sOrder = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3};
      final sc = (sOrder[a.severity] ?? 4).compareTo(sOrder[b.severity] ?? 4);
      if (sc != 0) return sc;
      return b.time.compareTo(a.time);
    });

    return alerts.take(15).toList();
  }

  // ── USGS Earthquakes ──────────────────────────────────────────────────────
  static Future<List<LiveAlert>> _fetchEarthquakes(
      double userLat, double userLng) async {
    final res = await http
        .get(Uri.parse(_usgsUrl))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return [];

    final j        = jsonDecode(res.body);
    final features = (j['features'] as List?) ?? [];
    final alerts   = <LiveAlert>[];

    for (final f in features) {
      final props = f['properties'];
      final geom  = f['geometry'];
      if (props == null || geom == null) continue;

      final coords = geom['coordinates'] as List?;
      if (coords == null || coords.length < 2) continue;

      final eqLng  = (coords[0] as num).toDouble();
      final eqLat  = (coords[1] as num).toDouble();
      final mag    = (props['mag'] as num?)?.toDouble() ?? 0.0;
      final place  = props['place'] as String? ?? 'Unknown region';
      final tsMs   = props['time'] as int? ?? 0;
      final time   = DateTime.fromMillisecondsSinceEpoch(tsMs);

      // Distance in km
      final distKm = _distKm(userLat, userLng, eqLat, eqLng);

      // Only include earthquakes within 500 km and mag >= 2.5
      if (distKm > 500 || mag < 2.5) continue;

      final severity = mag >= 6.0 ? 'CRITICAL'
          : mag >= 5.0 ? 'HIGH'
          : mag >= 4.0 ? 'MEDIUM'
          : 'LOW';

      alerts.add(LiveAlert(
        id:          'eq_${f['id']}',
        title:       'Earthquake M${mag.toStringAsFixed(1)} — $place',
        type:        'EARTHQUAKE',
        severity:    severity,
        location:    place,
        description: 'Magnitude ${mag.toStringAsFixed(1)} earthquake detected '
            '${distKm.toStringAsFixed(0)} km away. '
            '${mag >= 5.0 ? "Expect aftershocks. Move to open areas." : "Minor tremors possible."}',
        time:        time,
        magnitude:   mag,
        lat:         eqLat,
        lng:         eqLng,
        isActive:    DateTime.now().difference(time).inHours < 12,
      ));
    }

    return alerts;
  }

  // ── Weather-based Alerts from OpenWeatherMap ──────────────────────────────
  static Future<List<LiveAlert>> _fetchWeatherAlerts(
      double lat, double lng) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$lat&lon=$lng&appid=${ApiKeys.openWeather}&units=metric');
    final res = await http.get(url).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];

    final j           = jsonDecode(res.body);
    final tempC       = (j['main']?['temp'] as num?)?.toDouble();
    final windMs      = (j['wind']?['speed'] as num?)?.toDouble();
    final windKph     = windMs != null ? windMs * 3.6 : null;
    final weatherMain = (j['weather'] as List?)?.first?['main'] as String?;
    final weatherDesc = (j['weather'] as List?)?.first?['description'] as String?;
    final humidity    = (j['main']?['humidity'] as num?)?.toDouble();
    final cityName    = j['name'] as String? ?? 'your area';

    return _buildWeatherAlerts(
      lat: lat, lng: lng, tempC: tempC, windKph: windKph,
      weatherMain: weatherMain, weatherDesc: weatherDesc,
      humidity: humidity, cityName: cityName,
    );
  }

  static List<LiveAlert> _buildWeatherAlerts({
    required double lat, required double lng,
    double? tempC, double? windKph, String? weatherMain,
    String? weatherDesc, double? humidity, String? cityName,
  }) {
    final alerts  = <LiveAlert>[];
    final loc     = cityName ?? 'your area';
    final now     = DateTime.now();
    final weather = (weatherMain ?? '').toLowerCase();
    final desc    = (weatherDesc ?? '').toLowerCase();

    // Thunderstorm
    if (weather.contains('thunderstorm')) {
      alerts.add(LiveAlert(
        id: 'wx_thunder_${now.millisecondsSinceEpoch}',
        title: 'Thunderstorm Warning — $loc',
        type: 'STORM', severity: 'HIGH',
        location: loc,
        description: 'Active thunderstorm detected. Stay indoors, avoid trees and open areas. '
            'Unplug electronics. ${desc.contains('heavy') ? "Heavy lightning expected." : ""}',
        time: now, lat: lat, lng: lng,
      ));
    }

    // Heavy Rain / Flood risk
    if (weather.contains('rain') && (desc.contains('heavy') || desc.contains('extreme'))) {
      alerts.add(LiveAlert(
        id: 'wx_flood_${now.millisecondsSinceEpoch}',
        title: 'Flash Flood Risk — $loc',
        type: 'FLOOD', severity: desc.contains('extreme') ? 'CRITICAL' : 'HIGH',
        location: loc,
        description: 'Heavy rainfall increasing flood risk. Avoid low-lying areas, '
            'wadis, and storm drains. Do not attempt to drive through floodwater.',
        time: now, lat: lat, lng: lng,
      ));
    } else if (weather.contains('rain')) {
      alerts.add(LiveAlert(
        id: 'wx_rain_${now.millisecondsSinceEpoch}',
        title: 'Rainfall Advisory — $loc',
        type: 'FLOOD', severity: 'LOW',
        location: loc,
        description: 'Moderate rainfall. Drive cautiously and watch for reduced visibility.',
        time: now, lat: lat, lng: lng,
      ));
    }

    // Drizzle/Mist — low severity
    if (weather.contains('drizzle') || weather.contains('mist') || weather.contains('fog')) {
      alerts.add(LiveAlert(
        id: 'wx_fog_${now.millisecondsSinceEpoch}',
        title: 'Low Visibility Advisory — $loc',
        type: 'STORM', severity: 'LOW',
        location: loc,
        description: 'Foggy or misty conditions reducing visibility. Drive with headlights, '
            'maintain safe following distance.',
        time: now, lat: lat, lng: lng,
      ));
    }

    // High wind
    if (windKph != null && windKph > 60) {
      alerts.add(LiveAlert(
        id: 'wx_wind_${now.millisecondsSinceEpoch}',
        title: 'High Wind Warning — ${windKph.toInt()} km/h in $loc',
        type: 'WIND', severity: windKph > 90 ? 'CRITICAL' : 'HIGH',
        location: loc,
        description: 'Dangerous wind speeds detected (${windKph.toInt()} km/h). '
            'Secure loose objects, avoid outdoor activities. '
            '${windKph > 90 ? "Structural damage possible." : "Falling branches risk."}',
        time: now, lat: lat, lng: lng,
      ));
    } else if (windKph != null && windKph > 40) {
      alerts.add(LiveAlert(
        id: 'wx_wind_med_${now.millisecondsSinceEpoch}',
        title: 'Elevated Wind Advisory — $loc',
        type: 'WIND', severity: 'MEDIUM',
        location: loc,
        description: 'Strong winds (${windKph.toInt()} km/h). Exercise caution outdoors.',
        time: now, lat: lat, lng: lng,
      ));
    }

    // Extreme heat
    if (tempC != null && tempC > 42) {
      alerts.add(LiveAlert(
        id: 'wx_heat_${now.millisecondsSinceEpoch}',
        title: 'Extreme Heat Alert — ${tempC.toStringAsFixed(0)}°C in $loc',
        type: 'HEAT', severity: tempC > 47 ? 'CRITICAL' : 'HIGH',
        location: loc,
        description: 'Dangerously high temperature (${tempC.toStringAsFixed(0)}°C). '
            'Stay indoors with AC, drink water every 30 min, avoid direct sun 10am–4pm. '
            'Check on elderly and children.',
        time: now, lat: lat, lng: lng,
      ));
    } else if (tempC != null && tempC > 38) {
      alerts.add(LiveAlert(
        id: 'wx_heat_med_${now.millisecondsSinceEpoch}',
        title: 'Heat Advisory — ${tempC.toStringAsFixed(0)}°C in $loc',
        type: 'HEAT', severity: 'MEDIUM',
        location: loc,
        description: 'High temperature (${tempC.toStringAsFixed(0)}°C). Stay hydrated and '
            'limit outdoor exertion during peak hours.',
        time: now, lat: lat, lng: lng,
      ));
    }

    // Snow / Blizzard
    if (weather.contains('snow') || weather.contains('blizzard')) {
      alerts.add(LiveAlert(
        id: 'wx_snow_${now.millisecondsSinceEpoch}',
        title: 'Winter Storm Warning — $loc',
        type: 'STORM', severity: desc.contains('heavy') ? 'HIGH' : 'MEDIUM',
        location: loc,
        description: 'Snow/ice conditions. Roads may be slippery. '
            'Limit travel, keep emergency kit in vehicle.',
        time: now, lat: lat, lng: lng,
      ));
    }

    // High humidity + heat = feels-like danger
    if (tempC != null && humidity != null && tempC > 35 && humidity > 80) {
      alerts.add(LiveAlert(
        id: 'wx_humid_${now.millisecondsSinceEpoch}',
        title: 'Dangerous Heat Index — $loc',
        type: 'HEAT', severity: 'HIGH',
        location: loc,
        description: 'Combined heat (${tempC.toStringAsFixed(0)}°C) and humidity '
            '(${humidity.toInt()}%) creates dangerously high heat index. '
            'Risk of heat stroke. Stay cool and hydrated.',
        time: now, lat: lat, lng: lng,
      ));
    }

    return alerts;
  }

  static double _distKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _deg2rad(double deg) => deg * math.pi / 180;
}
