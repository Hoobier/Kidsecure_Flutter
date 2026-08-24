import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../models/student.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

// lib/routes/app_router.dart

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

    GoRoute(
      path: '/settings',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SettingsScreen(
          parentName: extra?['parentName'] as String? ?? 'Parent',
          parentEmail: extra?['parentEmail'] as String?,
          students: (extra?['students'] as List<Student>?) ?? const [],
        );
      },
    ),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactScreen(),
    ),
  ],
); // GoRouter
