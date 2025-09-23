import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/utils/constants/text_styles.dart';
import 'package:android_app/screens/admin/auth/new_password_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String email;

  const VerificationCodeScreen({super.key, required this.email});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
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

                  // Right section (Verification code form)
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
                          Text('Nhập mã xác minh', style: AppTextStyles.title),
                          const SizedBox(height: 44),

                          Text(
                            'Chúng tôi vừa gửi mã gồm 6 chữ số đến email của bạn. Vui lòng kiểm tra',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF27252E),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 40),

                          // Verification code field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Opacity(
                              opacity: 0.8,
                              child: Text(
                                'Mã xác minh',
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
                              controller: _codeController,
                              style: AppTextStyles.bodyText.copyWith(
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '123456',
                                hintStyle: TextStyle(
                                  fontFamily: 'Nunito Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  letterSpacing: -0.06,
                                  color: Color(0xFFA6A6A6),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Verify button
                          SizedBox(
                            width: 418,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle verification
                                print(
                                  'Verification code: ${_codeController.text}',
                                );

                                // Simulate successful verification
                                if (_codeController.text.length == 6) {
                                  // Navigate to new password screen
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => NewPasswordScreen(
                                        email: widget.email,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng nhập mã xác minh 6 số',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Xác minh',
                                style: AppTextStyles.buttonText,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Resend code button
                          TextButton(
                            onPressed: () {
                              // Handle resend code
                              print('Resend code to: ${widget.email}');
                            },
                            child: Text(
                              'Gửi lại mã',
                              style: AdditionalTextStyles.subtleText,
                            ),
                          ),

                          const SizedBox(height: 10),
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
