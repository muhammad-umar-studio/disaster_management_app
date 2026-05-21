import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/supabase_service.dart';

enum SosState { idle, countdown, active, cancelled }

class SosProvider extends ChangeNotifier {
  SosState      _state       = SosState.idle;
  int           _countdown   = 5;
  bool          _locationShared = false;
  String        _status      = 'Standby — Hold SOS to activate';
  LocationData? _location;

  // Flashlight state
  bool _torchOn    = false;
  bool _torchAvailable = true;

  // Alert state
  bool _alertSent  = false;

  // WhatsApp Alert state
  bool _sendViaWhatsApp = false;

  SosState get sosState       => _state;
  bool     get isActivated    => _state == SosState.active;
  bool     get isCountingDown => _state == SosState.countdown;
  bool     get locationShared => _locationShared;
  int      get countdown      => _countdown;
  String   get status         => _status;
  bool     get torchOn        => _torchOn;
  bool     get alertSent      => _alertSent;
  bool     get sendViaWhatsApp => _sendViaWhatsApp;
  LocationData? get location  => _location;

  void toggleSendViaWhatsApp(bool v) {
    _sendViaWhatsApp = v;
    notifyListeners();
  }

  String get locationString {
    if (_location == null) return 'Getting location...';
    return '${_location!.latitude.toStringAsFixed(5)}, ${_location!.longitude.toStringAsFixed(5)} · ${_location!.city}';
  }

  String get mapsLink {
    if (_location == null) return '';
    return 'https://maps.google.com/?q=${_location!.latitude},${_location!.longitude}';
  }

  // ── SOS Activation ───────────────────────────────────────────────────────
  Future<void> startSos() async {
    if (_state != SosState.idle) return;
    _state     = SosState.countdown;
    _countdown = 5;
    _status    = 'SOS activating in $_countdown seconds...';
    notifyListeners();

    // Fetch location in background
    _location = await LocationService.getCurrentLocation();

    while (_countdown > 0 && _state == SosState.countdown) {
      await Future.delayed(const Duration(seconds: 1));
      if (_state != SosState.countdown) return;
      _countdown--;
      _status = _countdown > 0 ? 'SOS activating in $_countdown seconds...' : 'ACTIVATING SOS...';
      notifyListeners();
    }
    if (_state == SosState.countdown) await _activate();
  }

  Future<void> _activate() async {
    _state          = SosState.active;
    _locationShared = true;
    _location       = await LocationService.getCurrentLocation();
    _status         = '🚨 SOS ACTIVE — Emergency services alerted';
    notifyListeners();

    // Auto-alert contacts when SOS activates
    await alertAllContacts(silent: true);

    // Call emergency contact immediately at once!
    await callEmergencyContact();
  }

  void cancelSos() {
    _state          = SosState.idle;
    _countdown      = 5;
    _locationShared = false;
    _alertSent      = false;
    _status         = 'SOS Cancelled — Standby mode';
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      if (_state == SosState.idle) {
        _status = 'Standby — Hold SOS to activate';
        notifyListeners();
      }
    });
  }

  // ── Quick Action 1: Share Location ────────────────────────────────────────
  Future<void> shareLocation() async {
    _status = 'Getting your location...';
    notifyListeners();

    _location = await LocationService.getCurrentLocation();
    if (_location == null) {
      _status = '⚠️ Could not get GPS location. Enable location.';
      notifyListeners();
      return;
    }

    _locationShared = true;
    _status         = '📍 Sharing location: ${_location!.city}';
    notifyListeners();

    final text = '🆘 EMERGENCY — My location:\n'
        '${_location!.address}\n\n'
        '📍 Open in Maps: $mapsLink\n'
        '— Sent via AEGIS';

    await Share.share(text, subject: '🆘 Emergency Location');
  }

  // ── Quick Action 2: Call Emergency Contact ────────────────────────────────
  Future<void> callEmergencyContact() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      // Fallback: open dialer with 911
      await _dialNumber('911');
      return;
    }

    final contacts = await SupabaseService.getContacts(userId);
    if (contacts.isEmpty) {
      // No contacts — dial 911
      await _dialNumber('911');
      return;
    }

    // Call first contact
    final phone = contacts.first['phone'] as String? ?? '911';
    _status = '📞 Calling ${contacts.first['name']}...';
    notifyListeners();
    await _dialNumber(phone);
  }

  Future<void> _dialNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Quick Action 3: Flashlight Toggle ────────────────────────────────────
  Future<void> toggleFlashlight() async {
    if (!_torchAvailable) return;
    try {
      if (_torchOn) {
        await TorchLight.disableTorch();
        _torchOn = false;
        _status  = '🔦 Flashlight OFF';
      } else {
        await TorchLight.enableTorch();
        _torchOn = true;
        _status  = '🔦 Flashlight ON — Signaling for help';
      }
      notifyListeners();
    } on Exception {
      _torchAvailable = false;
      _status = '⚠️ No flashlight available on this device';
      notifyListeners();
    }
  }

  // ── Quick Action 4: Alert All Contacts ───────────────────────────────────
  Future<void> alertAllContacts({bool silent = false}) async {
    _location ??= await LocationService.getCurrentLocation();

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      if (!silent) {
        _status = '⚠️ Sign in to alert your emergency contacts';
        notifyListeners();
      }
      return;
    }

    final contacts = await SupabaseService.getContacts(userId);
    if (contacts.isEmpty) {
      if (!silent) {
        _status = '⚠️ No emergency contacts found. Add contacts in Profile.';
        notifyListeners();
      }
      return;
    }

    final locText = _location != null
        ? '${_location!.address}\n📍 $mapsLink'
        : 'Location unavailable';

    // Send SMS or WhatsApp to all contacts
    for (final c in contacts) {
      final phone   = c['phone'] as String? ?? '';
      if (phone.isEmpty) continue;

      final msg = '🆘 EMERGENCY ALERT from ${SupabaseService.currentUser?.email ?? "an AEGIS user"}!\n'
          'I need immediate help at:\n$locText\n'
          '— AEGIS Emergency System';

      if (_sendViaWhatsApp) {
        final cleanPhone = _formatWhatsAppPhone(phone);
        final waUri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        await Future.delayed(const Duration(milliseconds: 1000));
      } else {
        final smsUri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(msg)}');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    _alertSent = true;
    _status    = '📢 Alert sent to ${contacts.length} contact(s)!';
    notifyListeners();

    // Log to event history
    if (_location != null) {
      await SupabaseService.addEvent(
        userId:   userId,
        title:    'SOS Alert Sent to ${contacts.length} contacts',
        type:     'SOS',
        location: _location!.city,
        severity: 'CRITICAL',
      );
    }
  }

  String _formatWhatsAppPhone(String phone) {
    // 1. Remove all non-digits
    String clean = phone.replaceAll(RegExp(r'\D'), '');

    // 2. If it starts with '00', remove the leading '00'
    if (clean.startsWith('00')) {
      clean = clean.substring(2);
    }

    // 3. Handle Pakistani numbers specifically
    if (clean.startsWith('92')) {
      // Check if it has a leading 0 after 92, like '920300...'
      if (clean.substring(2).startsWith('0')) {
        clean = '92${clean.substring(3)}'; // Remove the '0'
      }
    } else {
      // If it doesn't start with '92', check if it starts with '03' (length 11) or '3' (length 10)
      if (clean.startsWith('0') && clean.length == 11) {
        clean = '92${clean.substring(1)}';
      } else if (clean.startsWith('3') && clean.length == 10) {
        clean = '92$clean';
      }
    }

    return clean;
  }
}
