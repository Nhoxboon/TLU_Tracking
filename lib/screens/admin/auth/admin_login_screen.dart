import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/utils/constants/text_styles.dart';
import 'package:android_app/screens/admin/auth/forgot_password_screen.dart';
import 'package:android_app/utils/admin_utils.dart';
import 'package:android_app/utils/auth_manager.dart';
import 'package:android_app/services/auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _rememberPassword = false;
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Reset auth state whenever this screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force reset the auth state in case we're coming back after logout
      final authManager = AuthManager();
      authManager.logout(); // Reset auth state

      // Also reset AuthService
      _authService.logout();

      // Clear form fields to ensure clean start
      _usernameController.clear();
      _passwordController.clear();
      setState(() {
        _isLoading = false;
        _rememberPassword = false;
        _obscureText = true;
      });

      print("AdminLoginScreen initialized - auth state and UI reset");

      // Clear any existing SnackBars
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  void _showLoginError(String message) {
    if (!mounted) return;

    print("Showing login error: $message");

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Phương thức xử lý đăng nhập
  Future<void> _handleLogin() async {
    if (_isLoading) return;

    // Get input values
    final email = _usernameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showLoginError('Vui lòng nhập đầy đủ email và mật khẩu');
      return;
    }

    print("Login attempt with: $email"); // Debug log

    setState(() {
      _isLoading = true;
    });

    try {
      // Use AuthService for authentication
      final result = await _authService.login(email, password);

      print("Authentication result: ${result['success']}"); // Debug log

      if (result['success'] == true) {
        // Login successful and user is admin
        // Also update old systems for compatibility
        AdminUtils.updateAdminLastLogin();

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        }
      } else {
        // Show error message from AuthService
        if (mounted) {
          _showLoginError(result['message'] ?? 'Đăng nhập thất bại');
        }
      }
    } catch (e) {
      print('Lỗi khi đăng nhập: $e');
      if (mounted) {
        _showLoginError('Có lỗi xảy ra khi đăng nhập: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Decorative circles based on Figma design
          Positioned(top: -722, left: -201, child: _buildDecorationCircles()),

          // Main content
          Center(
            child: Container(
              width: 1107,
              height: 735,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFB9B9B9), width: 0.3),
              ),
              child: Row(
                children: [
                  // Left section (Logo and app name)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Replace with actual image
                          Container(
                            width: 388,
                            height: 323,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  'assets/images/Logo-DH-Thuy-Loi.webp',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'TLU',
                                  style: AppTextStyles.heading.copyWith(
                                    color: const Color(0xFF2196F3),
                                  ),
                                ),
                                TextSpan(
                                  text: ' Tracking',
                                  style: AppTextStyles.heading,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right section (Login form)
                  SizedBox(
                    width: 516,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48.0,
                        vertical: 127.0,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đăng nhập', style: AppTextStyles.title),
                            const SizedBox(height: 40),

                            // Email field
                            Text('Email', style: AppTextStyles.bodyText),
                            const SizedBox(height: 15),
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: _usernameController,
                                style: AppTextStyles.bodyText,
                                keyboardType: TextInputType.emailAddress,
                                onSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'email@example.com',
                                  hintStyle: AppTextStyles.bodyTextLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Password field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Mật khẩu', style: AppTextStyles.bodyText),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: AdditionalTextStyles.subtleText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.inputBorder,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _passwordController,
                                      obscureText: _obscureText,
                                      style: AppTextStyles.bodyText,
                                      onSubmitted: (_) => _handleLogin(),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '••••••',
                                        hintStyle: AppTextStyles.bodyTextLight,
                                      ),
                                    ),
                                  ),
                                  // Toggle password visibility button
                                  IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textPrimary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Remember password checkbox
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberPassword,
                                    activeColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.checkboxBorder,
                                      width: 0.6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _rememberPassword = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Nhớ mật khẩu',
                                  style: AdditionalTextStyles.subtleText,
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),

                            // Login button
                            SizedBox(
                              width: 418,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Đăng nhập',
                                        style: AppTextStyles.buttonText,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to create decorative circles based on Figma design
  Widget _buildDecorationCircles() {
    return SizedBox(
      width: 2307.22,
      height: 2320.22,
      child: Stack(
        children: [
          // Circle 1
          Positioned(
            left: 26,
            top: 1207,
            child: Container(
              width: 895,
              height: 895,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
              ),
            ),
          ),

          // Circle 2
          Positioned(
            left: 975,
            top: 0,
            child: Opacity(
              opacity: 0.542,
              child: Container(
                width: 1207.11,
                height: 1207.11,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),

          // Circle 3
          Positioned(
            left: 0,
            top: 335,
            child: Opacity(
              opacity: 0.6,
              child: Container(
                width: 1147.13,
                height: 1147.13,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),

          // Circle 4
          Positioned(
            left: 975,
            top: 988,
            child: Container(
              width: 1332.22,
              height: 1332.22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
