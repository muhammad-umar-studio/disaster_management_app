import 'package:flutter/material.dart';
import '../../../core/services/alert_service.dart';
import '../../../core/services/location_service.dart';
import '../../notifications/providers/notification_provider.dart';

class AlertProvider extends ChangeNotifier {
  List<LiveAlert> _alerts    = [];
  LiveAlert?      _selected;
  bool            _isLoading = false;
  String          _error     = '';
  DateTime?       _lastFetch;

  List<LiveAlert> get alerts       => _alerts;
  List<LiveAlert> get activeAlerts => _alerts.where((a) => a.isActive).toList();
  LiveAlert?      get selectedAlert => _selected;
  bool            get isLoading    => _isLoading;
  String          get error        => _error;
  bool            get hasActiveAlerts => activeAlerts.isNotEmpty;

  String get systemStatus {
    if (_isLoading) return 'SCANNING...';
    final crit = _alerts.where((a) => a.severity == 'CRITICAL').length;
    final high = _alerts.where((a) => a.severity == 'HIGH').length;
    if (crit > 0) return 'CRITICAL THREAT ACTIVE';
    if (high > 0) return 'ACTIVE THREAT DETECTED';
    if (_alerts.isNotEmpty) return 'MONITORING — LOW RISK';
    return 'REGION SECURE';
  }

  NotificationProvider? _notifProvider;

  void setNotificationProvider(NotificationProvider p) => _notifProvider = p;

  AlertProvider() {
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 10 &&
        _alerts.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error     = '';
    notifyListeners();

    try {
      final loc = LocationService.cached ??
          await LocationService.getCurrentLocation();

      double lat = 24.8607, lng = 67.0011;
      if (loc != null) { lat = loc.latitude; lng = loc.longitude; }

      _alerts    = await AlertService.fetchAlerts(lat: lat, lng: lng);
      _lastFetch = DateTime.now();

      // Sync to notification provider
      _notifProvider?.syncFromAlerts(_alerts);
    } catch (e) {
      _error  = 'Could not fetch real-time alerts.';
      _alerts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => _loadAlerts();

  void selectAlert(String id) {
    _selected = _alerts.firstWhere((a) => a.id == id,
        orElse: () => _alerts.first);
    notifyListeners();
  }

  LiveAlert? getAlertById(String id) {
    try { return _alerts.firstWhere((a) => a.id == id); }
    catch (_) { return null; }
  }

  Color getSeverityColor(String severity) {
    switch (severity) {
      case 'CRITICAL': return const Color(0xFFFF3B30);
      case 'HIGH':     return const Color(0xFFFF9F0A);
      case 'MEDIUM':   return const Color(0xFFFFD60A);
      case 'LOW':      return const Color(0xFF30D158);
      default:         return const Color(0xFF6B7A99);
    }
  }

  Color getAlertTypeColor(String type) {
    switch (type) {
      case 'EARTHQUAKE': return const Color(0xFFFF9F0A);
      case 'STORM':      return const Color(0xFF7C3AED);
      case 'FLOOD':      return const Color(0xFF0099CC);
      case 'HEAT':       return const Color(0xFFFF3B30);
      case 'WIND':       return const Color(0xFF6B7A99);
      default:           return const Color(0xFF6B7A99);
    }
  }

  IconData getAlertTypeIcon(String type) {
    switch (type) {
      case 'EARTHQUAKE': return Icons.crisis_alert_rounded;
      case 'STORM':      return Icons.storm_rounded;
      case 'FLOOD':      return Icons.water_rounded;
      case 'HEAT':       return Icons.wb_sunny_rounded;
      case 'WIND':       return Icons.air_rounded;
      default:           return Icons.warning_rounded;
    }
  }
}
