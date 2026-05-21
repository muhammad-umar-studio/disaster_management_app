import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/alert_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
  });
}

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  final Set<String> _seenAlertIds = {};
  
  Timer? _autoUpdateTimer;
  bool _autoUpdatesEnabled = false; // Disabled by default to prevent spamming
  int _templateIndex = 0;

  NotificationProvider() {
    _startAutoUpdates();
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get autoUpdatesEnabled => _autoUpdatesEnabled;

  final List<Map<String, String>> _alertTemplates = [
    {
      'title': '⛈️ Weather Alert: Coastal Winds',
      'body': 'PMD warns of high-speed winds (up to 65 km/h) in Gwadar and coastal areas of Balochistan. Sea conditions are rough. Fishermen advised to remain cautious.',
      'type': 'warning',
    },
    {
      'title': '🌊 River Level Alert: Indus Flow',
      'body': 'NDMA reports Indus River flow levels are stable near Sukkur Barrage. Pre-emptive rescue camps have been successfully set up by local authorities.',
      'type': 'success',
    },
    {
      'title': '🚨 Monsoon warning: Clifton, Karachi',
      'body': 'Severe urban flooding risk detected in low-lying areas of Karachi. Rescue 1122 teams are on high alert. Avoid non-essential travel.',
      'type': 'critical',
    },
    {
      'title': '⚡ Seismic Alert: Northern Punjab',
      'body': 'A minor 4.2 magnitude tremor was recorded 45km north of Islamabad. No casualties or structural damages have been reported.',
      'type': 'info',
    },
    {
      'title': '🚑 Dispatch: Edhi Emergency Team',
      'body': 'Edhi Foundation has deployed 4 special relief trucks containing dry food and medical kits to flood-affected sectors in Quetta.',
      'type': 'success',
    },
    {
      'title': '🌡️ Heatwave Alert: Southern Sindh',
      'body': 'Temperatures in Jacobabad and Larkana are projected to cross 47°C. Dedicated hydration centers have been established by local support groups.',
      'type': 'warning',
    },
    {
      'title': '🏔️ Landslide advisory: Karakoram Highway',
      'body': 'Minor landslides reported near Hunza Valley due to recent rain. Road clearance operations are underway by FWO. Expect delays.',
      'type': 'warning',
    },
    {
      'title': '📡 System Update: AEGIS Satellite Sync',
      'body': 'Emergency communication networks have synced with Pakistan regional weather satellites. Real-time monitoring coverage is 100% active.',
      'type': 'success',
    },
    {
      'title': '🚨 High Emergency: Multan Road, Lahore',
      'body': 'Accident response unit triggered. Rescue 1122 has dispatched advanced life support ambulances to the scene. Route diverted.',
      'type': 'critical',
    },
    {
      'title': '💧 Water level warning: Rawal Lake',
      'body': 'Water spillways at Rawal Dam, Islamabad have been safely opened following heavy inflow. Downstream residents are advised to stay clear of the banks.',
      'type': 'info',
    },
  ];

  void toggleAutoUpdates(bool enabled) {
    _autoUpdatesEnabled = enabled;
    if (_autoUpdatesEnabled) {
      _startAutoUpdates();
    } else {
      _autoUpdateTimer?.cancel();
      _autoUpdateTimer = null;
    }
    notifyListeners();
  }

  void _startAutoUpdates() {
    _autoUpdateTimer?.cancel();
    if (!_autoUpdatesEnabled) return;

    _autoUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_autoUpdatesEnabled) {
        _generateRandomAlert();
      }
    });
  }

  void _generateRandomAlert() {
    if (_alertTemplates.isEmpty) return;
    final template = _alertTemplates[_templateIndex % _alertTemplates.length];
    _templateIndex++;

    addCustomNotification(
      title: template['title']!,
      body: template['body']!,
      type: template['type']!,
    );
  }

  void addCustomNotification({
    required String title,
    required String body,
    required String type,
  }) {
    _notifications.insert(0, AppNotification(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      time: DateTime.now(),
    ));
    // Keep max 30 notifications
    while (_notifications.length > 30) {
      _notifications.removeLast();
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  void generateDemoAlerts() {
    // Instantly generate 3 different alerts to populate the empty feed beautifully
    for (int i = 0; i < 3; i++) {
      _generateRandomAlert();
    }
  }

  /// Called by AlertProvider after every fetch to sync real alerts as notifications
  void syncFromAlerts(List<LiveAlert> alerts) {
    bool changed = false;
    for (final alert in alerts) {
      if (_seenAlertIds.contains(alert.id)) continue;
      _seenAlertIds.add(alert.id);

      _notifications.insert(0, AppNotification(
        id:    alert.id,
        title: _titleFor(alert),
        body:  alert.description,
        type:  _typeFor(alert.severity),
        time:  alert.time,
      ));
      changed = true;
    }
    if (changed) {
      // Keep max 30 notifications
      while (_notifications.length > 30) _notifications.removeLast();
      notifyListeners();
    }
  }

  /// Call this when user activates SOS
  void addSosNotification({required String location}) {
    _notifications.insert(0, AppNotification(
      id:    'sos_${DateTime.now().millisecondsSinceEpoch}',
      title: '🚨 SOS Activated',
      body:  'Emergency SOS was activated at $location. Contacts have been alerted.',
      type:  'critical',
      time:  DateTime.now(),
    ));
    notifyListeners();
  }

  /// Call when location is shared
  void addLocationSharedNotification() {
    _notifications.insert(0, AppNotification(
      id:    'loc_${DateTime.now().millisecondsSinceEpoch}',
      title: '📍 Location Shared',
      body:  'Your live location has been shared with emergency contacts.',
      type:  'info',
      time:  DateTime.now(),
    ));
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  String _titleFor(LiveAlert alert) {
    switch (alert.type) {
      case 'EARTHQUAKE': return '⚡ Earthquake ${alert.magnitude != null ? "M${alert.magnitude!.toStringAsFixed(1)}" : ""} — ${alert.location}';
      case 'FLOOD':      return '🌊 Flood Alert — ${alert.location}';
      case 'STORM':      return '⛈️ Storm Warning — ${alert.location}';
      case 'HEAT':       return '🌡️ Heat Alert — ${alert.location}';
      case 'WIND':       return '💨 Wind Warning — ${alert.location}';
      default:           return '⚠️ ${alert.title}';
    }
  }

  String _typeFor(String severity) {
    switch (severity) {
      case 'CRITICAL': return 'critical';
      case 'HIGH':     return 'warning';
      case 'MEDIUM':   return 'info';
      default:         return 'info';
    }
  }

  Color getTypeColor(String type) {
    switch (type) {
      case 'critical': return const Color(0xFFFF3B30);
      case 'warning':  return const Color(0xFFFF9F0A);
      case 'info':     return const Color(0xFF00D4FF);
      case 'success':  return const Color(0xFF30D158);
      default:         return const Color(0xFF6B7A99);
    }
  }

  IconData getTypeIcon(String type) {
    switch (type) {
      case 'critical': return Icons.warning_rounded;
      case 'warning':  return Icons.error_outline_rounded;
      case 'info':     return Icons.info_outline_rounded;
      case 'success':  return Icons.check_circle_outline_rounded;
      default:         return Icons.notifications_rounded;
    }
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    super.dispose();
  }
}
