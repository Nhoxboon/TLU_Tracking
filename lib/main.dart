import 'package:android_app/screens/teacher/teacher_session_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'models/api_models.dart';
import 'screens/teacher/teacher_class_detail_screen.dart';
import 'services/user_session.dart';
import 'package:android_app/screens/admin/auth/admin_login_screen.dart';
import 'package:android_app/screens/admin/dashboard/admin_dashboard_screen.dart';
import 'package:android_app/screens/admin/dashboard/class_management/class_students_view.dart';
import 'package:android_app/screens/onboarding/onboarding_screen.dart';
import 'package:android_app/screens/users/auth/login_screen.dart';
import 'package:android_app/screens/users/auth/forgot_password_screen.dart';
import 'package:android_app/screens/users/auth/reset_password_screen.dart';
import 'package:android_app/screens/teacher/teacher_dashboard_screen.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/student/student_session_detail_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/face_scanner_screen.dart';
import 'screens/student_settings_screen.dart';
import 'screens/face_registration_screen.dart';
import 'screens/change_password_screen.dart';
import 'utils/navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserSession().restore();
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
      navigatorObservers: [routeObserver],
      routes: {
        '/': (context) => UserSession().isLoggedIn
            ? _homeByRole()
            : (kIsWeb ? const AdminLoginScreen() : const OnboardingScreen()),
        '/admin/login': (context) => const AdminLoginScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/class-students': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ClassStudentsView(
            classCode: args['classCode'] as String,
            className: args['className'] as String,
          );
        },
        '/class-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return TeacherClassDetailScreen(
            classId: args?['classId'] as int? ?? 1,
            classCode: args?['classCode'] as String? ?? 'CSE',
          );
        },
        '/onboarding': (context) => const OnboardingScreen(),
        '/student/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/teacher/dashboard': (context) => const TeacherDashboardScreen(),
        // Student routes
        '/student/home': (context) => const StudentHomeScreen(),
        '/student/settings': (context) => const StudentSettingsScreen(),
        '/face/registration': (context) => const FaceRegistrationScreen(),
        '/change/password': (context) => const ChangePasswordScreen(),
        '/session/detail': (context) => const StudentSessionDetailScreen(),
        '/qr/scanner': (context) => const QRScannerScreen(),
        '/face/scanner': (context) => const FaceScannerScreen(),
        // '/student/login': (context) => const ClassDetailScreen(classCode: 'CSE'), // Temporary redirect to ClassDetailScreen
      },
    );
  }
}

Widget _homeByRole() {
  final role = UserSession().userRole;
  switch (role) {
    case UserRole.admin:
      return const AdminDashboardScreen();
    case UserRole.teacher:
      return const TeacherDashboardScreen();
    case UserRole.student:
    default:
      return const StudentHomeScreen();
  }
}
