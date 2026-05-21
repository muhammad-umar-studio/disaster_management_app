import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/services/alert_service.dart';
import '../../alerts/providers/alert_provider.dart';

class AlertDetailScreen extends StatefulWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});
  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertProv = context.watch<AlertProvider>();
    final alert = alertProv.getAlertById(widget.alertId);

    if (alert == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: const Center(child: Text('Alert not found', style: TextStyle(color: AppColors.textPrimary))),
      );
    }

    final typeColor = alertProv.getAlertTypeColor(alert.type);
    final icon      = alertProv.getAlertTypeIcon(alert.type);

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [typeColor.withOpacity(0.1), AppColors.bgDeep, AppColors.bgDeep],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context, alert, typeColor, icon)),
              SliverToBoxAdapter(child: _gauge(alert, typeColor)),
              SliverToBoxAdapter(child: _analysis(alert, typeColor)),
              SliverToBoxAdapter(child: _instructions(alert)),
              SliverToBoxAdapter(child: _actions(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext ctx, LiveAlert alert, Color color, IconData icon) {
    final diff       = DateTime.now().difference(alert.time);
    final timeLabel  = diff.inMinutes < 60 ? '${diff.inMinutes}m ago' : '${diff.inHours}h ago';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => ctx.pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.bgCard.withOpacity(0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderPrimary)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textPrimary),
            ),
          ),
          const Spacer(),
          if (alert.isActive) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.dangerRed.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.borderRed)),
            child: const Text('ACTIVE ALERT', style: TextStyle(color: AppColors.dangerRed, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ]),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Text(alert.type, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
        ),
        const SizedBox(height: 10),
        Text(alert.title, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 14),
          const SizedBox(width: 4),
          Text(alert.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(timeLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        Text(alert.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
        if (alert.magnitude != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
            child: Row(children: [
              Icon(Icons.crisis_alert_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text('Magnitude: ${alert.magnitude!.toStringAsFixed(1)}', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
        const SizedBox(height: 20),
      ]),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _gauge(LiveAlert alert, Color color) {
    final severity = alert.severity;
    final riskScore = severity == 'CRITICAL' ? 90.0
        : severity == 'HIGH' ? 72.0
        : severity == 'MEDIUM' ? 50.0
        : 25.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.25))),
        child: Column(children: [
          const Text('THREAT LEVEL', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _progressCtrl,
            builder: (ctx, _) => SizedBox(
              width: 160, height: 160,
              child: CustomPaint(
                painter: _GaugePainter(_progressCtrl.value * riskScore / 100, color),
                child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${(riskScore * _progressCtrl.value).toInt()}%',
                    style: TextStyle(color: color, fontSize: 38, fontWeight: FontWeight.w800)),
                  Text(severity, style: const TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ])),
              ),
            ),
          ),
        ]),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _analysis(LiveAlert alert, Color color) {
    // Build contextual AI analysis based on alert type
    final analysisPoints = _getAnalysis(alert);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderPrimary)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.psychology_rounded, color: color, size: 20),
            const SizedBox(width: 8),
            const Text('AI Analysis', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          ...analysisPoints.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 3, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.key, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(e.value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
              ])),
            ]),
          )),
        ]),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _instructions(LiveAlert alert) {
    final steps = _getSafetySteps(alert);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderPrimary)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.checklist_rounded, color: AppColors.warningOrange, size: 20),
            SizedBox(width: 8),
            Text('Safety Instructions', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: AppColors.warningOrange.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: AppColors.warningOrange.withOpacity(0.4))),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.warningOrange, fontSize: 10, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5))),
            ]),
          )),
        ]),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _actions(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(children: [
        SizedBox(
          width: double.infinity, height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.redGradient, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.dangerRed.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))]),
            child: ElevatedButton.icon(
              onPressed: () => ctx.go('/sos'),
              icon: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
              label: const Text('Activate SOS Emergency', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 50,
          child: OutlinedButton.icon(
            onPressed: () => ctx.go('/map'),
            icon: const Icon(Icons.map_rounded, color: AppColors.cyanPrimary, size: 18),
            label: const Text('View Safe Zone Map', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.borderPrimary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
      ]),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ── Contextual helpers ────────────────────────────────────────────────────
  Map<String, String> _getAnalysis(LiveAlert a) {
    switch (a.type) {
      case 'EARTHQUAKE':
        return {
          'Seismic Activity': 'Magnitude ${a.magnitude?.toStringAsFixed(1) ?? "?"} event detected. Aftershocks expected in next 24–48 hours.',
          'Structural Risk': 'Older buildings at risk of partial collapse. Avoid damaged structures.',
          'Recommended Action': 'Move to open ground away from buildings, power lines, and trees.',
        };
      case 'FLOOD':
        return {
          'Water Level': 'Rising water detected in low-lying areas. Drainage systems may be overwhelmed.',
          'Urban Risk': 'Streets, underpasses and basement levels are at highest risk.',
          'Recommended Action': 'Move to higher ground immediately. Do not drive through floodwater.',
        };
      case 'STORM':
        return {
          'Atmospheric Conditions': 'Severe storm system active in your region.',
          'Hazards': 'Lightning, strong winds, and hail are likely. Power outages possible.',
          'Recommended Action': 'Stay indoors, away from windows. Unplug electronics.',
        };
      case 'HEAT':
        return {
          'Temperature': 'Dangerously high heat index in your area.',
          'Health Risk': 'Heat stroke and dehydration risk is elevated, especially for elderly.',
          'Recommended Action': 'Stay in air-conditioned spaces, drink water every 30 min.',
        };
      default:
        return {
          'Alert Origin': 'AI monitoring system detected an anomaly.',
          'Risk Level': a.severity,
          'Recommended Action': 'Follow local authority guidance and stay informed.',
        };
    }
  }

  List<String> _getSafetySteps(LiveAlert a) {
    switch (a.type) {
      case 'EARTHQUAKE':
        return [
          'Drop, Cover, and Hold On — get under a sturdy table or desk',
          'Stay away from windows, heavy furniture, and outer walls',
          'After shaking stops, check for injuries and evacuate carefully',
          'Expect aftershocks — stay in open areas away from buildings',
          'Do not use elevators. Check gas lines for leaks.',
        ];
      case 'FLOOD':
        return [
          'Move to higher ground immediately — do not wait',
          'Do not walk or drive through floodwater (15 cm can knock you down)',
          'Turn off utilities at main switches if safe to do so',
          'Disconnect electrical appliances — do not touch if wet',
          'Listen to emergency broadcasts for evacuation routes',
        ];
      case 'STORM':
        return [
          'Stay indoors, away from windows and glass doors',
          'Unplug electronics and avoid corded phones',
          'If outside, seek shelter in a low-lying area away from trees',
          'Avoid contact with water during lightning storm',
          'Keep emergency kit accessible (torch, first aid, radio)',
        ];
      case 'HEAT':
        return [
          'Stay indoors in air-conditioned rooms between 10am–4pm',
          'Drink water every 30 minutes — do not wait until thirsty',
          'Wear loose, light-coloured clothing',
          'Check on elderly neighbours and vulnerable family members',
          'Never leave children or pets in parked vehicles',
        ];
      default:
        return [
          'Stay informed via official emergency broadcasts',
          'Keep your phone charged and emergency contacts ready',
          'Follow instructions from local authorities',
          'Prepare emergency go-bag if evacuation is ordered',
        ];
    }
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _GaugePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final bgPaint = Paint()..color = AppColors.bgSurface..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle, endAngle: startAngle + sweepAngle * progress,
          colors: [color.withOpacity(0.5), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.progress != progress;
}
