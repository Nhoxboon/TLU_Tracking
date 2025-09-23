import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
// import 'package:android_app/utils/constants/text_styles.dart';
import 'package:android_app/screens/admin/auth/verification_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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

                  // Right section (Forgot password form)
                  SizedBox(
                    width: 516,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48.0,
                        vertical: 127.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Quên mật khẩu', style: AppTextStyles.title),
                          const SizedBox(height: 44),

                          Text(
                            'Nhập địa chỉ email để đặt lại mật khẩu',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF27252E),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Email field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Opacity(
                              opacity: 0.8,
                              child: Text(
                                'Email:',
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
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _emailController,
                              style: AppTextStyles.bodyText,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'esteban_schiller@gmail.com',
                                hintStyle: AppTextStyles.bodyTextLight,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Send code button
                          SizedBox(
                            width: 418,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle sending reset password code
                                print('Email: ${_emailController.text}');

                                // Navigate to verification code screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VerificationCodeScreen(
                                          email: _emailController.text,
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Gửi mã',
                                style: AppTextStyles.buttonText,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // // Back to login
                          // TextButton(
                          //   onPressed: () {
                          //     Navigator.of(context).pop();
                          //   },
                          //   child: Text(
                          //     'Quay lại đăng nhập',
                          //     style: AdditionalTextStyles.subtleText,
                          //   ),
                          // ),
                        ],
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
