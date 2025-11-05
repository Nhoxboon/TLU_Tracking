import 'package:flutter/material.dart';
import 'student/edit_profile_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/user_session.dart';
import '../utils/auth_manager.dart';
import '../services/api_service.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool _isLoading = true;
  String? _error;
  
  // User data fields
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _birthDate = '';
  String _hometown = '';
  String _studentCode = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService().getCurrentUser();
      
      if (response.success && response.data != null) {
        final userData = response.data!;
        final profile = userData['profile'] as Map<String, dynamic>?;
        
        if (profile != null) {
          setState(() {
            _fullName = profile['full_name'] ?? '';
            _email = userData['email'] ?? '';
            _phone = profile['phone'] ?? '';
            _hometown = profile['hometown'] ?? '';
            
            // Format birth date from yyyy-MM-dd to dd/MM/yyyy
            final birthDateStr = profile['birth_date'] as String?;
            if (birthDateStr != null && birthDateStr.isNotEmpty) {
              try {
                final parts = birthDateStr.split('-');
                if (parts.length == 3) {
                  _birthDate = '${parts[2]}/${parts[1]}/${parts[0]}';
                } else {
                  _birthDate = birthDateStr;
                }
              } catch (_) {
                _birthDate = birthDateStr;
              }
            }
            
            // Get student code
            _studentCode = profile['student_code'] ?? '';
          });
        }
      } else {
        setState(() {
          _error = 'Không thể lấy thông tin người dùng';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchUserProfile,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    // Reserve space at the bottom so content doesn't overflow under
                    // the shared bottom navigation bar.
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),

                          // Header with back button and title
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
                              const SizedBox(width: 31),
                              const Text(
                                'Cài đặt',
                                style: TextStyle(
                                  fontFamily: 'Sen',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF181C2E),
                                  height: 1.29,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 31),

                          // Profile name
                          Text(
                            _fullName.isNotEmpty ? _fullName : (UserSession().username ?? 'Sinh viên'),
                            style: const TextStyle(
                              fontFamily: 'Sen',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF32343E),
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 31),

                          // Personal Information Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F8FA),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Edit information link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const StudentEditProfileScreen(),
                                        ),
                                      ).then((_) => _fetchUserProfile());
                                    },
                                    child: const Text(
                                      'SỬA THÔNG TIN',
                                      style: TextStyle(
                                        fontFamily: 'Sen',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF2196F3),
                                        decoration: TextDecoration.underline,
                                        height: 2.0,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Student Code (if available)
                                if (_studentCode.isNotEmpty) ...[
                                  _buildPersonalInfoItem(
                                    icon: Icons.badge_outlined,
                                    label: 'MÃ SINH VIÊN',
                                    value: _studentCode,
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Name field
                                _buildPersonalInfoItem(
                                  icon: Icons.person_outline,
                                  label: 'TÊN',
                                  value: _fullName.isNotEmpty ? _fullName : 'Chưa cập nhật',
                                ),

                                const SizedBox(height: 20),

                                // Email field
                                _buildPersonalInfoItem(
                                  icon: Icons.email_outlined,
                                  label: 'EMAIL',
                                  value: _email.isNotEmpty ? _email : 'Chưa cập nhật',
                                ),

                                const SizedBox(height: 20),

                                // Birthday field
                                _buildPersonalInfoItem(
                                  icon: Icons.favorite_border,
                                  label: 'NGÀY SINH',
                                  value: _birthDate.isNotEmpty ? _birthDate : 'Chưa cập nhật',
                                ),

                                const SizedBox(height: 20),

                                // Hometown field
                                _buildPersonalInfoItem(
                                  icon: Icons.home_outlined,
                                  label: 'QUÊ QUÁN',
                                  value: _hometown.isNotEmpty ? _hometown : 'Chưa cập nhật',
                                ),

                                const SizedBox(height: 20),

                                // Phone field
                                _buildPersonalInfoItem(
                                  icon: Icons.phone_outlined,
                                  label: 'SỐ ĐIỆN THOẠI',
                                  value: _phone.isNotEmpty ? _phone : 'Chưa cập nhật',
                                ),
                              ],
                            ),
                                    ),

                          const SizedBox(height: 20),

                          // Change Password Button
                          _buildSettingsButton(
                            icon: Icons.key_outlined,
                            title: 'Đổi mật khẩu',
                            onTap: () {
                              Navigator.pushNamed(context, '/change/password');
                            },
                          ),

                          const SizedBox(height: 20),

                          // Face Registration Button
                          _buildSettingsButton(
                            icon: Icons.camera_alt_outlined,
                            title: 'Đăng ký khuôn mặt',
                            onTap: () {
                              Navigator.pushNamed(context, '/face/registration');
                            },
                          ),

                          const SizedBox(height: 20),

                          // Logout Button
                          _buildSettingsButton(
                            icon: Icons.logout_outlined,
                            title: 'Đăng xuất',
                            showArrow: true,
                            onTap: () {
                              _showLogoutDialog(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildPersonalInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        // Icon container
        Container(
          width: 42,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F2FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2196F3), size: 20),
        ),

        const SizedBox(width: 14),

        // Label and value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF32343E),
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B6E82),
                  height: 1.21,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showArrow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 42,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2196F3), size: 20),
            ),

            const SizedBox(width: 14),

            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF32343E),
                ),
              ),
            ),

            // Arrow icon for logout
            if (showArrow)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF6B6E82),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              fontFamily: 'Sen',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF32343E),
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',
            style: TextStyle(
              fontFamily: 'Sen',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B6E82),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B6E82),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Clear all auth/session states before navigating
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

                Navigator.pop(context);
                // Navigate to login screen and remove all previous routes
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/student/login',
                  (route) => false,
                );
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
