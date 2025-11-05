import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/auth_manager.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 40,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        titleSpacing: 5,
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              // Current password field
              _buildPasswordField(
                label: 'MẬT KHẨU CŨ',
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                onVisibilityToggle: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // New password field
              _buildPasswordField(
                label: 'MẬT KHẨU MỚI',
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                onVisibilityToggle: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Confirm new password field
              _buildPasswordField(
                label: 'XÁC NHẬN MẬT KHẨU MỚI',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                onVisibilityToggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              
              const SizedBox(height: 40),
              
              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    _changePassword();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'LƯU',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: GestureDetector(
                onTap: onVisibilityToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _changePassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate inputs
    if (newPassword != confirmPassword) {
      _showErrorDialog('Mật khẩu xác nhận không khớp');
      return;
    }

    if (newPassword.length < 6) {
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
        title: const Text(
          'Lỗi',
          style: TextStyle(
            fontFamily: 'Sen',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Sen',
                color: Color(0xFF2196F3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
