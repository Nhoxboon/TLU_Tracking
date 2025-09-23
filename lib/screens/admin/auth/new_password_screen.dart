import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({super.key, required this.email});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              height: 750, // Increased height slightly
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

                  // Right section (New password form)
                  SizedBox(
                    width: 516,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48.0,
                          vertical: 80.0, // Reduced vertical padding
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Mật khẩu mới', style: AppTextStyles.title),
                            const SizedBox(height: 60), // Reduced spacing
                            // New Password field
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Opacity(
                                opacity: 0.8,
                                child: Text(
                                  'Mật khẩu mới',
                                  style: AppTextStyles.bodyText,
                                ),
                              ),
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
                              child: TextField(
                                controller: _passwordController,
                                style: AppTextStyles.bodyText.copyWith(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF202224),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  hintText: '••••••',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Nunito Sans',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    letterSpacing: -0.06,
                                    color: Color(0xFFA6A6A6),
                                  ),
                                ),
                                obscureText: _obscurePassword,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Confirm Password field
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Opacity(
                                opacity: 0.8,
                                child: Text(
                                  'Xác nhận mật khẩu',
                                  style: AppTextStyles.bodyText,
                                ),
                              ),
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
                              child: TextField(
                                controller: _confirmPasswordController,
                                style: AppTextStyles.bodyText.copyWith(
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF202224),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  hintText: '••••••',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'Nunito Sans',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    letterSpacing: -0.06,
                                    color: Color(0xFFA6A6A6),
                                  ),
                                ),
                                obscureText: _obscureConfirmPassword,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Confirm button
                            SizedBox(
                              width: 418,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Validate passwords match
                                  if (_passwordController.text.isEmpty ||
                                      _confirmPasswordController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Vui lòng nhập đầy đủ thông tin',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (_passwordController.text !=
                                      _confirmPasswordController.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Mật khẩu không khớp'),
                                      ),
                                    );
                                    return;
                                  }

                                  // Handle password reset success
                                  print(
                                    'Password reset successful for ${widget.email}',
                                  );

                                  // Navigate to login screen or show success message
                                  // TODO: Implement navigation to appropriate screen
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Xác nhận',
                                  style: AppTextStyles.buttonText,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
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
