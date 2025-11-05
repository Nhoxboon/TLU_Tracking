import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/auth_manager.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final session = UserSession();
    // Try multiple sources to get email
    _userEmail = session.email ?? 
                 session.userData?['email'] as String? ?? 
                 (session.username?.contains('@') == true ? session.username : null);
    
    // If still null, try to get from current user API
    if (_userEmail == null || _userEmail!.isEmpty) {
      await _fetchEmailFromAPI();
    }
  }

  Future<void> _fetchEmailFromAPI() async {
    try {
      final response = await ApiService().getCurrentUser();
      if (response.success && response.data != null) {
        final userData = response.data!;
        if (mounted) {
          setState(() {
            _userEmail = userData['email'] as String? ?? 
                       (userData['username'] as String?);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching email from API: $e');
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    // Validate inputs
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Mật khẩu xác nhận không khớp');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorDialog('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }

    // Try to get email again if still null
    if (_userEmail == null || _userEmail!.isEmpty) {
      await _fetchEmailFromAPI();
      if (_userEmail == null || _userEmail!.isEmpty) {
        _showErrorDialog('Không thể lấy email của tài khoản. Vui lòng thử lại sau.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Call password-reset API to send OTP
      final resetResponse = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/password-reset'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': _userEmail}),
      );

      if (resetResponse.statusCode != 200) {
        final error = jsonDecode(resetResponse.body);
        throw Exception(error['detail'] ?? 'Không thể gửi mã OTP');
      }

      setState(() {
        _isLoading = false;
      });

      // Step 2: Show OTP input dialog
      if (mounted) {
        final otpVerified = await _showOTPDialog();
        if (!otpVerified) return;

        // Step 3 & 4: Verify OTP and update password
        await _verifyOTPAndUpdatePassword();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorDialog('Lỗi: ${e.toString()}');
      }
    }
  }

  Future<bool> _showOTPDialog() async {
    _otpController.clear();
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Nhập mã OTP',
          style: TextStyle(
            fontFamily: 'Sen',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mã OTP đã được gửi đến email: $_userEmail',
              style: const TextStyle(
                fontFamily: 'Sen',
                fontSize: 14,
                color: Color(0xFF6B6E82),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Mã OTP',
                hintText: 'Nhập 6 chữ số',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
              style: const TextStyle(
                fontSize: 18,
                letterSpacing: 2,
                fontFamily: 'Sen',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'Sen',
                color: Color(0xFF6B6E82),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_otpController.text.length == 6) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text(
              'Xác nhận',
              style: TextStyle(
                fontFamily: 'Sen',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _verifyOTPAndUpdatePassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 3: Verify OTP
      final verifyResponse = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _userEmail,
          'token': _otpController.text,
        }),
      );

      if (verifyResponse.statusCode != 200) {
        final error = jsonDecode(verifyResponse.body);
        throw Exception(error['detail'] ?? 'Mã OTP không hợp lệ');
      }

      final verifyData = jsonDecode(verifyResponse.body);
      final accessToken = verifyData['access_token'] as String?;

      if (accessToken == null) {
        throw Exception('Không nhận được access token');
      }

      // Step 4: Update password with new access token
      final updateResponse = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/update-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'new_password': _newPasswordController.text,
        }),
      );

      if (updateResponse.statusCode != 200) {
        final error = jsonDecode(updateResponse.body);
        throw Exception(error['detail'] ?? 'Không thể cập nhật mật khẩu');
      }

      setState(() {
        _isLoading = false;
      });

      // Step 5: Logout user
      if (mounted) {
        try {
          AuthManager().logout();
        } catch (_) {}
        try {
          AuthService().logout();
        } catch (_) {}
        try {
          UserService.instance.logout();
        } catch (_) {}
        try {
          UserSession().logout();
        } catch (_) {}

        // Show success dialog and navigate to login
        _showSuccessDialogAndLogout();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorDialog('Lỗi: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialogAndLogout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Thành công',
          style: TextStyle(
            fontFamily: 'Sen',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Đổi mật khẩu thành công! Vui lòng đăng nhập lại bằng mật khẩu mới.',
          style: TextStyle(
            fontFamily: 'Sen',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/student/login',
                (route) => false,
              );
            },
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                fontFamily: 'Sen',
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E1E1E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Đổi mật khẩu',
                    style: TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF32343E),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current password
                      const Text(
                        'Mật khẩu hiện tại',
                        style: TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF32343E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: !_isCurrentPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Nhập mật khẩu hiện tại',
                          hintStyle: const TextStyle(
                            color: Color(0xFF6B6E82),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2196F3)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isCurrentPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF6B6E82),
                            ),
                            onPressed: () {
                              setState(() {
                                _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // New password
                      const Text(
                        'Mật khẩu mới',
                        style: TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF32343E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: !_isNewPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Nhập mật khẩu mới',
                          hintStyle: const TextStyle(
                            color: Color(0xFF6B6E82),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2196F3)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isNewPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF6B6E82),
                            ),
                            onPressed: () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Confirm password
                      const Text(
                        'Xác nhận mật khẩu mới',
                        style: TextStyle(
                          fontFamily: 'Sen',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF32343E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Nhập lại mật khẩu mới',
                          hintStyle: const TextStyle(
                            color: Color(0xFF6B6E82),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2196F3)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF6B6E82),
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Change password button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                )
                              : const Text(
                                  'Đổi mật khẩu',
                                  style: TextStyle(
                                    fontFamily: 'Sen',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}