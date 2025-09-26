import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/users/class_detail_screen.dart';
import 'package:android_app/screens/admin/auth/admin_login_screen.dart';
import 'package:android_app/screens/admin/dashboard/admin_dashboard_screen.dart';
import 'package:android_app/screens/onboarding/onboarding_screen.dart';
import 'package:android_app/screens/users/auth/login_screen.dart';
import 'package:android_app/screens/users/auth/forgot_password_screen.dart';
import 'package:android_app/screens/users/auth/reset_password_screen.dart';
import 'package:android_app/utils/constants/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TLU Tracking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>
            kIsWeb ? const AdminLoginScreen() : const OnboardingScreen(),
        '/admin/login': (context) => const AdminLoginScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/class-detail': (context) => const ClassDetailScreen(classCode: 'CSE'),
        '/onboarding': (context) => const OnboardingScreen(),
        '/student/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
