import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/users/class_detail_screen.dart';
import 'package:android_app/screens/admin/auth/admin_login_screen.dart';
import 'package:android_app/screens/admin/dashboard/admin_dashboard_screen.dart';
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
      // Use AdminLoginScreen for web platforms and ClassDetailScreen for mobile platforms
      home: kIsWeb
          ? const AdminLoginScreen()
          : const ClassDetailScreen(classCode: 'CSE'),
      routes: {
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/class-detail': (context) => const ClassDetailScreen(classCode: 'CSE'),
      },
    );
  }
}