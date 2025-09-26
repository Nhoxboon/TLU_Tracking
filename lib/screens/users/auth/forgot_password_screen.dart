import 'package:flutter/material.dart';
import 'package:android_app/screens/users/auth/verification_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  bool _isEmailFocused = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocusChange);
  }

  void _onEmailFocusChange() {
    setState(() {
      _isEmailFocused = _emailFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.removeListener(_onEmailFocusChange);
    _emailFocus.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_emailController.text.trim().isEmpty) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email của bạn'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network request
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi mã xác thực đến email của bạn'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to verification code screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerificationCodeScreen(email: _emailController.text.trim()),
          ),
        );

        // Reset loading state
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // TLU Tracking Title
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.56,
                      height: 1.26,
                      color: Color(0xFF333333),
                    ),
                    children: [
                      TextSpan(
                        text: 'TLU',
                        style: TextStyle(color: Color(0xFF2196F3)),
                      ),
                      TextSpan(text: ' Tracking'),
                    ],
                  ),
                ),
                const SizedBox(height: 55),

                // Forgot Password Label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 64.0),
                    child: Text(
                      'Quên mật khẩu',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                        letterSpacing: -0.48,
                        height: 1.235,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Instruction text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Nhập địa chỉ email để đặt lại mật khẩu.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Color(0xFF333333),
                      letterSpacing: -0.28,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Email field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Label above input
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 15,
                            color: Color(0xFF333333),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Email',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              color: Color(0xFF333333),
                              letterSpacing: -0.2,
                              height: 1.235,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Input field
                    Container(
                      height: 45,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0x66333333),
                          width: 0.5,
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .25),
                            blurRadius: 4,
                            spreadRadius: -3,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Color(0xFF333333),
                          letterSpacing: -0.24,
                          height: 1.235,
                        ),
                        decoration: InputDecoration(
                          hintText: _isEmailFocused
                              ? ''
                              : '2251172312@e.tlu.edu.vn',
                          hintStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Color(0x99333333),
                            letterSpacing: -0.24,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Reset Password Button
                SizedBox(
                  width: 349,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(
                        0xFF2196F3,
                      ).withValues(alpha: 0.7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Đặt lại mật khẩu',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.4,
                              height: 1.26,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
