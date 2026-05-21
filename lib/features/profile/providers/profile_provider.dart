import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation;

  EmergencyContact({required this.id, required this.name, required this.phone, required this.relation});
  String get avatarInitial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  factory EmergencyContact.fromMap(Map<String, dynamic> m) => EmergencyContact(
    id:       m['id'] ?? '',
    name:     m['name'] ?? '',
    phone:    m['phone'] ?? '',
    relation: m['relation'] ?? 'Contact',
  );
}

class EventHistoryItem {
  final String id;
  final String title;
  final String type;
  final String location;
  final String severity;
  final DateTime date;

  EventHistoryItem({required this.id, required this.title, required this.type,
    required this.location, required this.severity, required this.date});

  factory EventHistoryItem.fromMap(Map<String, dynamic> m) => EventHistoryItem(
    id:       m['id'] ?? '',
    title:    m['title'] ?? '',
    type:     m['type'] ?? '',
    location: m['location'] ?? '',
    severity: m['severity'] ?? 'MODERATE',
    date:     DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
  );
}

class ProfileData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String bloodType;
  final List<String> medicalConditions;
  final String location;
  final int safetyScore;
  final String? avatarUrl;

  ProfileData({
    required this.id, required this.name, required this.email,
    required this.phone, required this.bloodType,
    required this.medicalConditions, required this.location,
    required this.safetyScore, this.avatarUrl,
  });

  factory ProfileData.fromMap(Map<String, dynamic> m) => ProfileData(
    id:                m['id'] ?? '',
    name:              m['name'] ?? 'User',
    email:             m['email'] ?? '',
    phone:             m['phone'] ?? '',
    bloodType:         m['blood_type'] ?? 'Unknown',
    medicalConditions: List<String>.from(m['medical_conditions'] ?? []),
    location:          m['location'] ?? '',
    safetyScore:       (m['safety_score'] as num?)?.toInt() ?? 85,
    avatarUrl:         m['avatar_url'],
  );
}

class ProfileProvider extends ChangeNotifier {
  ProfileData?           _profile;
  List<EmergencyContact> _contacts     = [];
  List<EventHistoryItem> _events       = [];
  bool                   _loading      = false;
  bool                   _contactsLoading = false;
  String?                _error;

  bool   get notificationsEnabled => _notificationsEnabled;
  bool   get locationEnabled      => _locationEnabled;
  bool   get sosAutoCall          => _sosAutoCall;

  bool _notificationsEnabled = true;
  bool _locationEnabled      = true;
  bool _sosAutoCall          = false;

  ProfileData?           get profile  => _profile;
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  List<EventHistoryItem> get events   => List.unmodifiable(_events);
  bool   get isLoading         => _loading;
  bool   get contactsLoading   => _contactsLoading;
  String? get error            => _error;

  Future<void> loadProfile(String userId) async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      final data = await SupabaseService.getProfile(userId);
      if (data != null) _profile = ProfileData.fromMap(data);
      await _loadContacts(userId);
      await _loadEvents(userId);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadContacts(String userId) async {
    final data = await SupabaseService.getContacts(userId);
    _contacts = data.map(EmergencyContact.fromMap).toList();
  }

  Future<void> _loadEvents(String userId) async {
    final data = await SupabaseService.getEventHistory(userId);
    _events = data.map(EventHistoryItem.fromMap).toList();
  }

  Future<void> addContact({required String userId, required String name,
      required String phone, required String relation}) async {
    _contactsLoading = true;
    notifyListeners();
    try {
      final res = await SupabaseService.addContact(
          userId: userId, name: name, phone: phone, relation: relation);
      _contacts.add(EmergencyContact.fromMap(res));
    } catch (e) {
      _error = 'Failed to add contact';
    }
    _contactsLoading = false;
    notifyListeners();
  }

  Future<void> deleteContact(String contactId) async {
    try {
      await SupabaseService.deleteContact(contactId);
      _contacts.removeWhere((c) => c.id == contactId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await SupabaseService.updateProfile(userId, data);
    await loadProfile(userId);
  }

  void toggleNotifications(bool v) { _notificationsEnabled = v; notifyListeners(); }
  void toggleLocation(bool v)      { _locationEnabled = v;      notifyListeners(); }
  void toggleSosAutoCall(bool v)   { _sosAutoCall = v;          notifyListeners(); }
}
