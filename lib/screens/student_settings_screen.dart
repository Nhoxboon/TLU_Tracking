import 'package:flutter/material.dart';

class StudentSettingsScreen extends StatelessWidget {
  const StudentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
              const Text(
                'Vishal Khadok',
                style: TextStyle(
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
                          // Navigate to edit profile
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
                    
                    // Name field
                    _buildPersonalInfoItem(
                      icon: Icons.person_outline,
                      label: 'TÊN',
                      value: 'Vishal Khadok',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Email field
                    _buildPersonalInfoItem(
                      icon: Icons.email_outlined,
                      label: 'EMAIL',
                      value: 'hello@halallab.co',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Birthday field
                    _buildPersonalInfoItem(
                      icon: Icons.favorite_border,
                      label: 'NGÀY SINH',
                      value: '15/02/1984',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Hometown field
                    _buildPersonalInfoItem(
                      icon: Icons.home_outlined,
                      label: 'QUÊ QUÁN',
                      value: 'Hải Dương',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Phone field
                    _buildPersonalInfoItem(
                      icon: Icons.phone_outlined,
                      label: 'SỐ ĐIỆN THOẠI',
                      value: '408-841-0926',
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
          child: Icon(
            icon,
            color: const Color(0xFF2196F3),
            size: 20,
          ),
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
              child: Icon(
                icon,
                color: const Color(0xFF2196F3),
                size: 20,
              ),
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
                Navigator.pop(context);
                // Navigate to login screen
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