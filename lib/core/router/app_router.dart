import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/alerts/screens/alert_detail_screen.dart';
import '../../features/map/screens/safe_zone_map_screen.dart';
import '../../features/sos/screens/sos_screen.dart';
import '../../features/chat/screens/ai_chat_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

import '../widgets/main_shell.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: false,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/alert-detail',
          builder: (context, state) {
            final alertId = state.extra as String? ?? '1';
            return AlertDetailScreen(alertId: alertId);
          },
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/map', builder: (context, state) => const SafeZoneMapScreen()),
            GoRoute(path: '/sos', builder: (context, state) => const SosScreen()),
            GoRoute(path: '/chat', builder: (context, state) => const AiChatScreen()),
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ],
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
  }
}
