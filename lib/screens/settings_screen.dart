import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'users/change_password_screen.dart';
import 'package:android_app/services/auth_service.dart';
import 'package:android_app/services/user_service.dart';
import 'package:android_app/services/user_session.dart';
import 'package:android_app/utils/auth_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 40,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        titleSpacing: 5,
        title: const Text(
          'Cài đặt',
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
              const SizedBox(height: 10),
              // User name and edit link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    UserSession().username ?? 'Sinh viên',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'SỬA THÔNG TIN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // User info container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Name
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      iconColor: Colors.deepOrange,
                      label: 'TÊN',
                      value: 'Vishal Khadok',
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      iconColor: Colors.blue,
                      label: 'EMAIL',
                      value: 'hello@halallab.co',
                    ),
                    const SizedBox(height: 16),
                    
                    // Date of birth
                    _buildInfoRow(
                      icon: Icons.favorite_border,
                      iconColor: Colors.red,
                      label: 'NGÀY SINH',
                      value: '15/02/1984',
                    ),
                    const SizedBox(height: 16),
                    
                    // Location
                    _buildInfoRow(
                      icon: Icons.home_outlined,
                      iconColor: Colors.blue,
                      label: 'QUÊ QUÁN',
                      value: 'Hải Dương',
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      iconColor: Colors.blue,
                      label: 'SỐ ĐIỆN THOẠI',
                      value: '408-841-0926',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Change Password Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Face Registration Button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/face/registration');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.face,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Đăng ký khuôn mặt',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Logout Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.logout,
                            size: 18,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                // Clear all auth/session states
                try { AuthManager().logout(); } catch (_) {}
                try { AuthService().logout(); } catch (_) {}
                try { UserService.instance.logout(); } catch (_) {}
                try { UserSession().logout(); } catch (_) {}

                // Close dialog
                Navigator.of(context).pop();
                // Navigate to login screen and clear history
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/student/login',
                  (route) => false,
                );
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
