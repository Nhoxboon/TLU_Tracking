import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top bar with back button and title
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 15, bottom: 25),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 24,
                      height: 24,
                      child: const Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Cài đặt',
                    style: TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF181C2E),
                    ),
                  ),
                ],
              ),
            ),
            
            // Profile info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _buildInfoItem(
                    title: 'Tên',
                    value: 'Vishal Khadok',
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  _buildInfoItem(
                    title: 'Email',
                    value: 'hello@halallab.co',
                  ),
                  const SizedBox(height: 16),
                  
                  // Birthday
                  _buildInfoItem(
                    title: 'Ngày sinh',
                    value: '15/02/1984',
                  ),
                  const SizedBox(height: 16),
                  
                  // Hometown
                  _buildInfoItem(
                    title: 'Quê quán',
                    value: 'Hải Dương',
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone
                  _buildInfoItem(
                    title: 'Số điện thoại',
                    value: '408-841-0926',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Edit Profile button
                  _buildActionButton(
                    context,
                    'Chỉnh sửa thông tin cá nhân',
                    Icons.edit,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Change Password button
                  _buildActionButton(
                    context,
                    'Đổi mật khẩu',
                    Icons.lock,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Logout button
                  _buildActionButton(
                    context,
                    'Đăng xuất',
                    Icons.logout,
                    isLogout: true,
                    onPressed: () {
                      // Logout logic here
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Đăng xuất'),
                            content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Hủy'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Đăng xuất'),
                                onPressed: () {
                                  // Handle logout action
                                  Navigator.of(context).pop();
                                  // Navigate to login screen or home
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Sen',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF32343E),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Sen',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B6E82),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon, {
    required VoidCallback onPressed,
    bool isLogout = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isLogout ? Colors.red.shade50 : Colors.white,
        foregroundColor: isLogout ? Colors.red : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isLogout ? Colors.red.shade200 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
      ),
      child: Row(
        children: [
          SizedBox(width: 16),
          Icon(icon, size: 20),
          SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Sen',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isLogout ? Colors.red : Colors.black87,
            ),
          ),
          Spacer(),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: isLogout ? Colors.red : Colors.black45,
          ),
          SizedBox(width: 16),
        ],
      ),
    );
  }
}