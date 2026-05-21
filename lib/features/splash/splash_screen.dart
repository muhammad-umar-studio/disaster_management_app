import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _navigate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            // Ambient glow background
            Positioned(
              top: -100, left: -100,
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.cyanPrimary.withOpacity(0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: -120, right: -80,
              child: Container(
                width: 350, height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.aiPurple.withOpacity(0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (ctx, _) => Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyanPrimary.withOpacity(0.3 + 0.2 * _pulseController.value),
                            blurRadius: 30 + 20 * _pulseController.value,
                            spreadRadius: 5 + 5 * _pulseController.value,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 28),

                  // App name
                  const Text(
                    'AEGIS',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.3),

                  const SizedBox(height: 8),
                  const Text(
                    'CRISIS INTELLIGENCE PLATFORM',
                    style: TextStyle(
                      color: AppColors.cyanPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                  const SizedBox(height: 60),

                  // Loading bar
                  Container(
                    width: 180,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.borderPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(seconds: 3),
                      builder: (ctx, val, _) => FractionallySizedBox(
                        widthFactor: val,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.cyanGradient,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: AppColors.cyanPrimary.withOpacity(0.6), blurRadius: 8)],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 16),
                  const Text(
                    'Initializing AI systems...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),

            // Version tag
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: const Text(
                'v1.0.0 · Developed by NextGen Coders · Powered by AEGIS Intelligence',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDim, fontSize: 11),
              ).animate().fadeIn(delay: 1200.ms),
            ),
          ],
        ),
      ),
    );
  }
}
