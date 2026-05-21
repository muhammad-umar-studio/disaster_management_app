import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../providers/sos_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _flashCtrl;
  late AnimationController _voiceCtrl;
  late AnimationController _overlayCtrl;

  // Voice recognition
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady   = false;
  bool _isListening   = false;
  bool _voiceTriggerEnabled = false; // Gates continuous microphone monitoring
  String _voiceStatus = 'Ready — tap microphone to enable voice monitoring';
  String _liveText    = '';
  bool _showOverlay   = false;

  static const _triggers = ['help me', 'sos', 'emergency', 'send sos', 'activate emergency', 'mayday'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _ringCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _flashCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    _voiceCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _overlayCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth    = context.read<AuthProvider>();
      final profile = context.read<ProfileProvider>();
      if (auth.user != null && profile.contacts.isEmpty) {
        profile.loadProfile(auth.user!.id);
      }
      _initVoice();
    });
  }

  Future<void> _initVoice() async {
    _speechReady = await _speech.initialize(
      onError: (e) { if (mounted) setState(() { _isListening = false; _voiceTriggerEnabled = false; _voiceStatus = 'Mic error — tap to retry'; }); },
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
          // Auto-restart backup only if voice trigger monitoring is active
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _speechReady && _voiceTriggerEnabled && !_isListening) {
              _startListening();
            }
          });
        }
      },
    );
    if (mounted) {
      setState(() {
        if (_speechReady) {
          _voiceStatus = 'Voice monitoring standby — tap mic to enable';
        } else {
          _voiceStatus = 'Speech recognition not supported on this device';
        }
      });
    }
  }

  Future<void> _startListening() async {
    if (!_speechReady || _isListening) return;
    setState(() {
      _isListening = true;
      _liveText = '';
      _voiceStatus = 'Listening for trigger phrase...';
    });
    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.toLowerCase();
          setState(() => _liveText = result.recognizedWords);
          if (_checkTrigger(words)) {
            _speech.stop();
            _triggerVoiceSOS();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(minutes: 30),
          pauseFor: const Duration(minutes: 30),
          partialResults: true,
          localeId: 'en_US',
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('[Voice SOS] Speech listen error: $e');
    }
  }

  bool _checkTrigger(String text) {
    for (final trigger in _triggers) {
      if (text.contains(trigger)) return true;
    }
    return false;
  }

  Future<void> _triggerVoiceSOS() async {
    if (!mounted) return;
    setState(() {
      _showOverlay = true;
      _voiceStatus = '🚨 TRIGGER DETECTED — Activating SOS!';
      _voiceTriggerEnabled = false; // Disable continuous listening during alert
    });
    _overlayCtrl.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      context.read<SosProvider>().startSos();
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _showOverlay = false);
        _overlayCtrl.reset();
      }
    }
  }

  void _toggleVoice() {
    if (_voiceTriggerEnabled) {
      setState(() {
        _voiceTriggerEnabled = false;
        _isListening = false;
        _voiceStatus = 'Voice paused — tap mic to resume';
        _liveText = '';
      });
      _speech.stop();
    } else {
      setState(() {
        _voiceTriggerEnabled = true;
        _voiceStatus = 'Starting microphone...';
      });
      _startListening();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _flashCtrl.dispose();
    _voiceCtrl.dispose();
    _overlayCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(children: [
        // Main content
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: sos.isActivated
                  ? [AppColors.dangerRed.withOpacity(0.15), AppColors.bgDeep]
                  : _showOverlay
                      ? [AppColors.dangerRed.withOpacity(0.2), AppColors.bgDeep]
                      : [AppColors.bgDeep, AppColors.bgDeep],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(sos)),
                SliverToBoxAdapter(child: _buildSosButton(sos)),
                SliverToBoxAdapter(child: _buildStatus(sos)),
                SliverToBoxAdapter(child: _buildLocationCard(sos)),
                SliverToBoxAdapter(child: _buildContacts()),
                SliverToBoxAdapter(child: _buildQuickActions(context, sos)),
                SliverToBoxAdapter(child: _buildVoiceSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
        // Voice trigger overlay
        if (_showOverlay) _buildVoiceOverlay(),
      ]),
    );
  }

  // ── Emergency Trigger Overlay ─────────────────────────────────────────────
  Widget _buildVoiceOverlay() {
    return AnimatedBuilder(
      animation: _overlayCtrl,
      builder: (ctx, _) => Container(
        color: AppColors.dangerRed.withOpacity(0.85),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Pulsing siren
            AnimatedBuilder(
              animation: _ringCtrl,
              builder: (ctx, _) => Stack(alignment: Alignment.center, children: [
                ...[1, 2, 3].map((i) => Container(
                  width: 80.0 + i * 50 + 30 * math.sin(_ringCtrl.value * 2 * math.pi),
                  height: 80.0 + i * 50 + 30 * math.sin(_ringCtrl.value * 2 * math.pi),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity((0.5 - i * 0.12).clamp(0, 1)), width: 2),
                  ),
                )),
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency_rounded, color: AppColors.dangerRed, size: 44),
                ),
              ]),
            ),
            const SizedBox(height: 40),
            const Text('VOICE TRIGGER DETECTED', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            const Text('Activating SOS Emergency...', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 30),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(SosProvider sos) {
    final statusColor = sos.isActivated ? AppColors.dangerRed
        : sos.torchOn ? AppColors.warningOrange : AppColors.safeGreen;
    final statusLabel = sos.isActivated ? 'ACTIVE'
        : sos.isCountingDown ? 'COUNTDOWN'
        : sos.torchOn ? 'TORCH ON' : 'STANDBY';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SOS Emergency', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          Text('Emergency response system', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (ctx, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1 + 0.05 * _pulseCtrl.value),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ),
      ]),
    ).animate().fadeIn();
  }

  // ── SOS Button ────────────────────────────────────────────────────────────
  Widget _buildSosButton(SosProvider sos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseCtrl, _ringCtrl]),
          builder: (ctx, _) => Stack(alignment: Alignment.center, children: [
            if (sos.isActivated || sos.isCountingDown)
              ...[1, 2, 3].map((i) => Container(
                width: 120.0 + i * 50 + (sos.isActivated ? 20 * math.sin(_ringCtrl.value * 2 * math.pi) : 0),
                height: 120.0 + i * 50 + (sos.isActivated ? 20 * math.sin(_ringCtrl.value * 2 * math.pi) : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dangerRed.withOpacity((0.4 - i * 0.1).clamp(0.0, 1.0)), width: 1.5),
                ),
              )),
            GestureDetector(
              onLongPress: sos.isActivated ? null : sos.startSos,
              onTap: sos.isActivated ? sos.cancelSos : null,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: sos.isActivated
                      ? [AppColors.dangerRedLight, AppColors.dangerRed]
                      : sos.isCountingDown
                          ? [AppColors.dangerRed.withOpacity(0.8), AppColors.dangerRed]
                          : [const Color(0xFF330A0A), const Color(0xFF1A0505)]),
                  border: Border.all(color: AppColors.dangerRed.withOpacity(0.5 + 0.3 * _pulseCtrl.value), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.dangerRed.withOpacity(0.4 + 0.2 * _pulseCtrl.value), blurRadius: 50 + 20 * _pulseCtrl.value, spreadRadius: 10 + 5 * _pulseCtrl.value),
                  ],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.emergency_rounded, color: Colors.white, size: sos.isActivated ? 44 : 36),
                  const SizedBox(height: 6),
                  if (sos.isCountingDown)
                    Text('${sos.countdown}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900))
                  else ...[
                    Text(sos.isActivated ? 'SOS ACTIVE' : 'SOS',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    Text(sos.isActivated ? 'TAP TO CANCEL' : 'HOLD TO ACTIVATE',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.elasticOut);
  }

  Widget _buildStatus(SosProvider sos) {
    if (!sos.isActivated && !sos.isCountingDown && sos.status.contains('Standby')) return const SizedBox(height: 16);
    final color = sos.isActivated ? AppColors.dangerRed : sos.torchOn ? AppColors.warningOrange : AppColors.cyanPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(sos.status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      ),
    ).animate().fadeIn().shake();
  }

  Widget _buildLocationCard(SosProvider sos) {
    if (sos.location == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cyanGlow, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderCyan)),
        child: Row(children: [
          const Icon(Icons.gps_fixed_rounded, color: AppColors.cyanPrimary, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sos.location!.city, style: const TextStyle(color: AppColors.cyanPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            Text('${sos.location!.latitude.toStringAsFixed(4)}, ${sos.location!.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'monospace')),
          ])),
          const Icon(Icons.check_circle_rounded, color: AppColors.safeGreen, size: 16),
        ]),
      ),
    );
  }

  Widget _buildContacts() {
    final profile  = context.watch<ProfileProvider>();
    final contacts = profile.contacts;
    if (contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Emergency Contacts', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderPrimary)),
            child: const Row(children: [
              Icon(Icons.person_add_rounded, color: AppColors.textMuted, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Add emergency contacts in Profile to alert them during SOS',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
            ]),
          ),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Emergency Contacts (${contacts.length})', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          height: 125,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: contacts.length,
            separatorBuilder: (_, index) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final c = contacts[i];
              return Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderPrimary)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 38, height: 38,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.cyanGradient),
                    child: Center(child: Text(c.avatarInitial, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(height: 6),
                  Text(c.name.split(' ').first, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
                  const SizedBox(height: 4),
                  Text(c.relation, style: const TextStyle(color: AppColors.textMuted, fontSize: 9), overflow: TextOverflow.ellipsis, maxLines: 1),
                ]),
              );
            },
          ),
        ),
      ]),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildQuickActions(BuildContext context, SosProvider sos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Actions', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _quickAction(label: 'Share\nLocation', icon: Icons.share_location_rounded, color: AppColors.cyanPrimary, active: sos.locationShared, onTap: sos.shareLocation)),
          const SizedBox(width: 10),
          Expanded(child: _quickAction(label: 'Call\nContact', icon: Icons.call_rounded, color: AppColors.safeGreen, active: false, onTap: sos.callEmergencyContact)),
          const SizedBox(width: 10),
          Expanded(child: _quickActionFlash(sos)),
          const SizedBox(width: 10),
          Expanded(child: _quickAction(label: sos.alertSent ? 'Alert\nSent ✓' : 'Alert\nAll', icon: Icons.campaign_rounded, color: AppColors.aiPurple, active: sos.alertSent, onTap: () => sos.alertAllContacts())),
        ]),
      ]),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _quickAction({required String label, required IconData icon, required Color color, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? color.withOpacity(0.6) : color.withOpacity(0.2)),
          boxShadow: active ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)] : [],
        ),
        child: Column(children: [
          Icon(icon, color: active ? color : color.withOpacity(0.7), size: 22),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? color : color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700, height: 1.3)),
        ]),
      ),
    );
  }

  Widget _quickActionFlash(SosProvider sos) {
    return GestureDetector(
      onTap: sos.toggleFlashlight,
      child: AnimatedBuilder(
        animation: _flashCtrl,
        builder: (ctx, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sos.torchOn ? AppColors.warningOrange.withOpacity(0.15 + 0.1 * _flashCtrl.value) : AppColors.warningOrange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sos.torchOn ? AppColors.warningOrange.withOpacity(0.6) : AppColors.warningOrange.withOpacity(0.2)),
            boxShadow: sos.torchOn ? [BoxShadow(color: AppColors.warningOrange.withOpacity(0.25 + 0.15 * _flashCtrl.value), blurRadius: 18)] : [],
          ),
          child: Column(children: [
            Icon(sos.torchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                color: sos.torchOn ? AppColors.warningOrange : AppColors.warningOrange.withOpacity(0.7), size: 22),
            const SizedBox(height: 5),
            Text(sos.torchOn ? 'Light\nON' : 'Flash\nLight',
                textAlign: TextAlign.center,
                style: TextStyle(color: sos.torchOn ? AppColors.warningOrange : AppColors.warningOrange.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700, height: 1.3)),
          ]),
        ),
      ),
    );
  }

  // ── Voice Section ─────────────────────────────────────────────────────────
  Widget _buildVoiceSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.aiPurple.withOpacity(0.08), AppColors.bgCard],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _isListening ? AppColors.aiPurple.withOpacity(0.5) : AppColors.aiPurple.withOpacity(0.2)),
          boxShadow: _isListening ? [BoxShadow(color: AppColors.aiPurple.withOpacity(0.15), blurRadius: 16)] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Mic button
            GestureDetector(
              onTap: _toggleVoice,
              child: AnimatedBuilder(
                animation: _voiceCtrl,
                builder: (ctx, _) => Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.dangerRed.withOpacity(0.15 + 0.1 * _voiceCtrl.value)
                        : AppColors.aiPurple.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isListening ? AppColors.dangerRed.withOpacity(0.6) : AppColors.aiPurple.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: _isListening ? [BoxShadow(color: AppColors.dangerRed.withOpacity(0.3 * _voiceCtrl.value), blurRadius: 14)] : [],
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                    color: _isListening ? AppColors.dangerRed : AppColors.aiPurple,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Voice Emergency Trigger', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(_voiceStatus, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            // Status badge
            AnimatedBuilder(
              animation: _voiceCtrl,
              builder: (ctx, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.dangerRed.withOpacity(0.1 + 0.05 * _voiceCtrl.value)
                      : AppColors.safeGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isListening ? AppColors.dangerRed.withOpacity(0.3) : AppColors.safeGreen.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _isListening ? 'ACTIVE' : 'PAUSED',
                  style: TextStyle(
                    color: _isListening ? AppColors.dangerRed : AppColors.safeGreen,
                    fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ]),
          if (_isListening) ...[
            const SizedBox(height: 12),
            // Live transcript
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Row(children: [
                // Animated waveform
                AnimatedBuilder(
                  animation: _voiceCtrl,
                  builder: (ctx, _) => Row(children: List.generate(6, (i) {
                    final h = 6.0 + 12 * math.sin(_voiceCtrl.value * math.pi + i * 0.9).abs();
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 3, height: h,
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed.withOpacity(0.5 + 0.5 * _voiceCtrl.value),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  })),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  _liveText.isNotEmpty ? _liveText : 'Say: "Help me" · "SOS" · "Emergency"',
                  style: TextStyle(
                    color: _liveText.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 11, fontStyle: _liveText.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: _triggers.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.aiPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.aiPurple.withOpacity(0.2)),
              ),
              child: Text('"$t"', style: const TextStyle(color: AppColors.aiPurple, fontSize: 9, fontWeight: FontWeight.w600)),
            )).toList()),
          ],
        ]),
      ),
    ).animate().fadeIn(delay: 350.ms);
  }
}
