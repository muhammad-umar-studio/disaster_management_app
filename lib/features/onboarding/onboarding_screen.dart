import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class _OnboardPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_OnboardPage> _pages = [
    _OnboardPage(
      title: 'Real-Time\nThreat Intelligence',
      subtitle: 'AI-POWERED MONITORING',
      description: 'Advanced machine learning analyzes thousands of data points per second — tracking wildfires, floods, earthquakes and storms before they reach you.',
      icon: Icons.radar_rounded,
      color: AppColors.cyanPrimary,
    ),
    _OnboardPage(
      title: 'Instant SOS\nEvacuation Support',
      subtitle: 'ONE-TAP EMERGENCY',
      description: 'A single tap dispatches rescue teams, shares your live location with emergency contacts, and routes you to the nearest safe haven instantly.',
      icon: Icons.emergency_rounded,
      color: AppColors.dangerRed,
    ),
    _OnboardPage(
      title: 'AI Crisis\nAssistant — 24/7',
      subtitle: 'INTELLIGENT GUIDANCE',
      description: 'Your personal AI disaster assistant provides real-time evacuation routes, safe zone locations, and survival instructions tailored to your situation.',
      icon: Icons.smart_toy_rounded,
      color: AppColors.aiPurple,
    ),
    _OnboardPage(
      title: 'Safe Zone\nNavigation',
      subtitle: 'LIVE SAFE ZONE MAP',
      description: 'Live-updated map showing verified shelters, hospitals, rescue stations, and hazard zones — with turn-by-turn guidance to safety.',
      icon: Icons.location_on_rounded,
      color: AppColors.safeGreen,
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (ctx, i) => _PageContent(page: _pages[i]),
              ),
            ),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottom() {
    final page = _pages[_page];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
      child: Column(
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _page ? 24 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _page ? page.color : AppColors.borderPrimary,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
          const SizedBox(height: 28),

          // Next button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [page.color, page.color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: page.color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _page == _pages.length - 1 ? 'Get Started' : 'Continue',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: const Text('Skip', style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Icon
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [page.color.withOpacity(0.2), Colors.transparent]),
              border: Border.all(color: page.color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(page.icon, color: page.color, size: 56),
          ).animate().scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.elasticOut).fadeIn(),

          const SizedBox(height: 36),

          Text(
            page.subtitle,
            style: TextStyle(
              color: page.color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5,
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.5),

          const SizedBox(height: 12),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 34, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

          const SizedBox(height: 20),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 15, height: 1.6,
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}
