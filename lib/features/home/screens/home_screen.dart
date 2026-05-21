import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/services/alert_service.dart';
import '../../../core/services/location_service.dart';
import '../../alerts/providers/alert_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _radarCtrl;
  late AnimationController _pulseCtrl;
  GoogleMapController? _mapController;
  LatLng _userLoc = const LatLng(24.8607, 67.0011);

  @override
  void initState() {
    super.initState();
    _radarCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final loc = LocationService.cached ?? await LocationService.getCurrentLocation();
    if (loc != null && mounted) {
      setState(() => _userLoc = LatLng(loc.latitude, loc.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLng(_userLoc));
    }
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final alerts = context.watch<AlertProvider>();
    final notifs = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => alerts.refresh(),
            color: AppColors.cyanPrimary,
            backgroundColor: AppColors.bgCard,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(notifs)),
                SliverToBoxAdapter(child: _buildSystemStatus(home, alerts)),
                SliverToBoxAdapter(child: _buildMapPreview()),
                SliverToBoxAdapter(child: _buildQuickStats(home)),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildWeatherCard(home)),
                SliverToBoxAdapter(child: _buildAlertsSection(alerts)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(NotificationProvider notifs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AEGIS', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  Text('CRISIS INTELLIGENCE', style: TextStyle(color: AppColors.cyanPrimary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
                ],
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderPrimary)),
                  child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 20),
                ),
                if (notifs.unreadCount > 0) Positioned(
                  right: 6, top: 6,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: AppColors.dangerRed, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.dangerRed.withOpacity(0.6), blurRadius: 4)]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [AppColors.cyanPrimary, AppColors.aiPurple]),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSystemStatus(HomeProvider home, AlertProvider alerts) {
    final hasAlert = alerts.hasActiveAlerts;
    final color = hasAlert ? AppColors.dangerRed : AppColors.safeGreen;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (ctx, _) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [color.withOpacity(0.12), AppColors.bgCard],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.3 + 0.15 * _pulseCtrl.value), width: 1.5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1 + 0.05 * _pulseCtrl.value), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                ),
                child: Icon(hasAlert ? Icons.warning_rounded : Icons.shield_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    home.systemStatus,
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasAlert ? '${alerts.activeAlerts.length} ACTIVE THREAT(S) DETECTED' : 'NO IMMEDIATE THREATS',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text('AI monitoring active · Updated just now', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('LIVE', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2);
  }

  Widget _buildMapPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => context.go('/map'),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderPrimary),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Real Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _userLoc, zoom: 13),
                  onMapCreated: (ctrl) async {
                    _mapController = ctrl;
                    await ctrl.setMapStyle(_homeMapStyle);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                ),
                // Radar sweep overlay
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _radarCtrl,
                    builder: (ctx, _) => CustomPaint(
                      size: const Size(double.infinity, 190),
                      painter: _RadarPainter(_radarCtrl.value),
                    ),
                  ),
                ),
                // Alert dots from real data
                IgnorePointer(
                  child: context.watch<AlertProvider>().alerts.take(3).toList().asMap().entries.map((e) {
                    final positions = [
                      const Offset(80, 60),
                      const Offset(220, 90),
                      const Offset(150, 120),
                    ];
                    final colors = [AppColors.dangerRed, AppColors.warningOrange, AppColors.safeGreen];
                    final labels = e.value.type;
                    final pos = positions[e.key % positions.length];
                    return Positioned(
                      left: pos.dx, top: pos.dy,
                      child: _mapDot(colors[e.key % colors.length], labels),
                    );
                  }).fold<Widget>(const SizedBox.shrink(), (prev, next) => Stack(children: [prev, next])),
                ),
                // Tactical View badge
                Positioned(
                  left: 16, top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(Icons.my_location_rounded, color: AppColors.cyanPrimary, size: 14),
                      SizedBox(width: 6),
                      Text('TACTICAL VIEW', style: TextStyle(color: AppColors.cyanPrimary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    ]),
                  ),
                ),
                // Scanning indicator
                Positioned(
                  left: 16, top: 42,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (ctx, _) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 5, height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.safeGreen.withOpacity(0.5 + 0.5 * _pulseCtrl.value),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppColors.safeGreen.withOpacity(0.5 * _pulseCtrl.value), blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text('SCANNING', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  right: 16, bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AppColors.cyanPrimary.withOpacity(0.4), blurRadius: 12)],
                    ),
                    child: const Text('Open Map', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _mapDot(Color color, String label) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (ctx, _) => Column(children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.5 + 0.3 * _pulseCtrl.value), blurRadius: 8 + 4 * _pulseCtrl.value, spreadRadius: 2)],
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _buildQuickStats(HomeProvider home) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(child: _statCard('AI SAFETY', '${home.aiSafetyScore}', 'score', home.safetyScoreColor, Icons.shield_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('RISK LEVEL', home.riskLevel, '', home.riskLevelColor, Icons.crisis_alert_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('WIND', '${home.windSpeed.toStringAsFixed(0)}', 'km/h', AppColors.cyanPrimary, Icons.air_rounded)),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _statCard(String label, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _actionBtn('SOS\nEmergency', Icons.emergency_rounded, AppColors.dangerRed, () => context.go('/sos'))),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('Safe\nZone Map', Icons.map_rounded, AppColors.cyanPrimary, () => context.go('/map'))),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('AI\nAssistant', Icons.smart_toy_rounded, AppColors.aiPurple, () => context.go('/chat'))),
          ]),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(HomeProvider home) {
    final w = home.weather;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A1035), Color(0xFF0A0E1A)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.aiPurple.withOpacity(0.2)),
        ),
        child: home.isLoading
          ? const Center(child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(color: AppColors.cyanPrimary, strokeWidth: 2)))
          : Row(children: [
              Icon(
                w?.isFireWeather == true ? Icons.local_fire_department_rounded
                  : w?.isFloodRisk == true ? Icons.water_rounded
                  : Icons.wb_sunny_rounded,
                color: w?.isFireWeather == true ? AppColors.dangerRed
                  : w?.isFloodRisk == true ? AppColors.cyanPrimary
                  : AppColors.warningOrange,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  w != null
                    ? '${w.tempF.toStringAsFixed(0)}°F · ${w.condition}'
                    : '-- · --',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  w != null
                    ? 'Humidity ${w.humidity}% · Wind ${w.windSpeedMph.toStringAsFixed(0)} mph ${w.windDirection}'
                    : 'Fetching weather...',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(home.locationName, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                if (w != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (w.isFireWeather ? AppColors.dangerRed : w.isFloodRisk ? AppColors.cyanPrimary : AppColors.safeGreen).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: w.isFireWeather ? AppColors.borderRed : AppColors.borderPrimary),
                    ),
                    child: Text(w.riskLabel, style: TextStyle(
                      color: w.isFireWeather ? AppColors.dangerRed : w.isFloodRisk ? AppColors.cyanPrimary : AppColors.safeGreen,
                      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  ),
                ],
              ])),
            ]),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }


  Widget _buildAlertsSection(AlertProvider alerts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Active Alerts',
            actionLabel: 'See all',
            onAction: () {},
          ),
          const SizedBox(height: 12),
          if (alerts.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.cyanPrimary, strokeWidth: 2),
            ))
          else
            for (final alert in alerts.alerts.take(3)) _AlertCard(alert: alert, provider: alerts),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }
}

class _AlertCard extends StatelessWidget {
  final LiveAlert alert;
  final AlertProvider provider;
  const _AlertCard({required this.alert, required this.provider});

  @override
  Widget build(BuildContext context) {
    final color     = provider.getSeverityColor(alert.severity);
    final typeColor = provider.getAlertTypeColor(alert.type);
    // Format time: 'X min ago' or 'X hr ago'
    final diff  = DateTime.now().difference(alert.time);
    final timeLabel = diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : '${diff.inHours}h ago';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: alert.isActive ? color.withOpacity(0.3) : AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(provider.getAlertTypeIcon(alert.type), color: typeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(alert.type, style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
              const SizedBox(width: 6),
              if (alert.isActive) Container(
                width: 5, height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ]),
            const SizedBox(height: 5),
            Text(alert.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('${alert.location} · $timeLabel', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ])),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3))),
            child: Text(alert.severity,
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

// Custom painters
class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = math.min(cx, cy) * 0.8;
    final angle = progress * 2 * math.pi;

    // Radar circles
    final circlePaint = Paint()..color = AppColors.cyanPrimary.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 0.8;
    canvas.drawCircle(Offset(cx, cy), r * 0.3, circlePaint);
    canvas.drawCircle(Offset(cx, cy), r * 0.6, circlePaint);
    canvas.drawCircle(Offset(cx, cy), r, circlePaint);

    // Sweep
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 0.8, endAngle: angle,
        colors: [Colors.transparent, AppColors.cyanPrimary.withOpacity(0.3)],
        center: Alignment.center,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, sweepPaint);

    // Sweep line
    final linePaint = Paint()..color = AppColors.cyanPrimary.withOpacity(0.8)..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx, cy), Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)), linePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.progress != progress;
}

const String _homeMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#0a0e1a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0e1a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6b7a99"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a2040"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1e3a5f"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#00e5ff"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0d1b2a"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#0d1520"}]}
]''';

