import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(_onPasswordFocusChange);
    _confirmPasswordFocus.addListener(_onConfirmPasswordFocusChange);
  }

  void _onPasswordFocusChange() {
    setState(() {
      _isPasswordFocused = _passwordFocus.hasFocus;
    });
  }

  void _onConfirmPasswordFocusChange() {
    setState(() {
      _isConfirmPasswordFocused = _confirmPasswordFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.removeListener(_onPasswordFocusChange);
    _confirmPasswordFocus.removeListener(_onConfirmPasswordFocusChange);
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    // Validate inputs
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate reset password process
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt lại mật khẩu thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to login screen
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/student/login', 
          (route) => false
        );
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
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      TextSpan(text: ' Tracking'),
                    ],
                  ),
                ),
                const SizedBox(height: 55),
                
                // Reset Password Label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 24.0),
                    child: Text(
                      'Đặt lại mật khẩu',
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
                
                // New Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Password Label above input
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 15,
                            color: Color(0xFF333333),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Mật khẩu mới',
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
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            spreadRadius: -3,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Color(0xFF333333),
                          letterSpacing: -0.24,
                          height: 1.235,
                        ),
                        decoration: InputDecoration(
                          hintText: _isPasswordFocused ? '' : '••••••••',
                          hintStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Color(0x99333333),
                            letterSpacing: -0.24,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                          isDense: true,
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: const Color(0xFF333333),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                
                // Confirm Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Confirm Password Label above input
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 15,
                            color: Color(0xFF333333),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Xác nhận mật khẩu',
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
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            spreadRadius: -3,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Color(0xFF333333),
                          letterSpacing: -0.24,
                          height: 1.235,
                        ),
                        decoration: InputDecoration(
                          hintText: _isConfirmPasswordFocused ? '' : '••••••••',
                          hintStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Color(0x99333333),
                            letterSpacing: -0.24,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                          isDense: true,
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: const Color(0xFF333333),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
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
                      disabledBackgroundColor: const Color(0xFF2196F3).withOpacity(0.7),
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
