import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
  }

  void _onEmailFocusChange() {
    setState(() {
      _isEmailFocused = _emailFocus.hasFocus;
    });
  }

  void _onPasswordFocusChange() {
    setState(() {
      _isPasswordFocused = _passwordFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.removeListener(_onEmailFocusChange);
    _passwordFocus.removeListener(_onPasswordFocusChange);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay for login
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        // Navigate to the class detail screen on successful login
        Navigator.pushReplacementNamed(context, '/class-detail');
        
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 65),
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
                
                // Login Label
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 24.0),
                    child: Text(
                      'Đăng nhập',
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
                
                // Username field
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
                            Icons.person_outline,
                            size: 15,
                            color: Color(0xFF333333),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tài khoản',
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
                          hintText: _isEmailFocused ? '' : '2251172312@e.tlu.edu.vn',
                          hintStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: Color(0x99333333),
                            letterSpacing: -0.24,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                
                // Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Password Label above input
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
                            'Mật khẩu',
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
                    // Password input field
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
                        obscureText: _obscureText,
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
                              _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: const Color(0xFF333333),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Forgot Password
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2196F3),
                        letterSpacing: -0.24,
                        height: 1.235,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Login Button
                SizedBox(
                  width: 349,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                            'Đăng nhập',
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
