import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/auth_manager.dart';

class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  bool _isLoading = true;
  String? _error;

  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _birthDate = '';
  String _hometown = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService().getCurrentUser();
      if (response.success && response.data != null) {
        final user = response.data!;
        final profile = user['profile'] as Map<String, dynamic>?;
        setState(() {
          _email = user['email'] ?? UserSession().username ?? '';
          if (profile != null) {
            _fullName = profile['full_name'] ?? '';
            _phone = profile['phone'] ?? profile['phone_number'] ?? '';
            _hometown = profile['hometown'] ?? '';
            final birth = profile['birth_date'] as String?;
            if (birth != null && birth.isNotEmpty) {
              try {
                final parts = birth.split('-');
                _birthDate = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : birth;
              } catch (_) {
                _birthDate = birth;
              }
            }
          }
        });
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
                      Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchProfile, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  // giữ không gian cho bottom nav nếu dùng chung
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
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
                        Text(
                          _fullName.isNotEmpty ? _fullName : (UserSession().username ?? 'Giảng viên'),
                          style: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF32343E),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 31),
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
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                                if (mounted) {
                                  _fetchProfile();
                                }
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
                              _buildInfoRow(
                                icon: Icons.person_outline,
                                iconColor: const Color(0xFF2196F3),
                                label: 'TÊN',
                                value: _fullName.isNotEmpty ? _fullName : 'Chưa cập nhật',
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                icon: Icons.email_outlined,
                                iconColor: const Color(0xFF2196F3),
                                label: 'EMAIL',
                                value: _email.isNotEmpty ? _email : 'Chưa cập nhật',
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                icon: Icons.favorite_border,
                                iconColor: const Color(0xFF2196F3),
                                label: 'NGÀY SINH',
                                value: _birthDate.isNotEmpty ? _birthDate : 'Chưa cập nhật',
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                icon: Icons.home_outlined,
                                iconColor: const Color(0xFF2196F3),
                                label: 'QUÊ QUÁN',
                                value: _hometown.isNotEmpty ? _hometown : 'Chưa cập nhật',
                              ),
                              const SizedBox(height: 20),
                              _buildInfoRow(
                                icon: Icons.phone_outlined,
                                iconColor: const Color(0xFF2196F3),
                                label: 'SỐ ĐIỆN THOẠI',
                                value: _phone.isNotEmpty ? _phone : 'Chưa cập nhật',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSettingsButton(
                          icon: Icons.key_outlined,
                          title: 'Đổi mật khẩu',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildSettingsButton(
                          icon: Icons.logout_outlined,
                          title: 'Đăng xuất',
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                          showArrow: true,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
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
                try { AuthManager().logout(); } catch (_) {}
                try { AuthService().logout(); } catch (_) {}
                try { UserService.instance.logout(); } catch (_) {}
                try { UserSession().logout(); } catch (_) {}

                Navigator.pop(context);
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


