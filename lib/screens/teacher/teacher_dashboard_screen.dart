import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'change_password_screen.dart';
import '../../services/user_session.dart';
import '../../services/api_service.dart';
import '../../models/api_models.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _selectedIndex = 0;

  // List of screens to display based on bottom navigation selection
  final List<Widget> _screens = [
    const _TeacherHomeTab(hasData: true), // Home tab with dynamic data loading
    const _TeacherSettingsTab(),          // Settings screen based on Figma design
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: const Color(0xFF333333),
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          height: 1.235,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10,
          height: 1.235,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            activeIcon: Icon(Icons.home, size: 24),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined, size: 24),
            activeIcon: Icon(Icons.settings, size: 24),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

// Home Tab with class data
class _TeacherHomeTab extends StatefulWidget {
  final bool hasData;

  const _TeacherHomeTab({Key? key, required this.hasData}) : super(key: key);

  @override
  State<_TeacherHomeTab> createState() => _TeacherHomeTabState();
}

class _TeacherHomeTabState extends State<_TeacherHomeTab> {
  List<ClassInfo> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    try {
      // First get current user data
      final userResponse = await ApiService().getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        final userData = userResponse.data!.user;

        // Then get classes by teacher ID
        final teacherId = userData['id']?.toString() ?? userData['teacher_id']?.toString();
        if (teacherId != null) {
          final classesResponse = await ApiService().getClassesByTeacher(teacherId);
          if (classesResponse.success && classesResponse.data != null) {
            setState(() {
              _classes = classesResponse.data!;
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      print('Error fetching teacher data: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isNotEmpty
              ? _buildHomeWithData(context)
              : _buildEmptyState(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Search box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm lớp',
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF999999),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Classes label
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Các lớp của bạn',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
                letterSpacing: -0.4,
                height: 1.26,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/class_empty_list.svg',
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa có lớp',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                      letterSpacing: -0.32,
                      height: 1.235,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Danh sách lớp của bạn sẽ được thể hiện ở đây, hãy đợi nhà trường thêm bạn vào.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF757575),
                        letterSpacing: -0.28,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // This would be implemented when we have data to display
  Widget _buildHomeWithData(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Search box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm lớp',
                hintStyle: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF999999),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Classes label
          const Text(
            'Các lớp của bạn',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
              letterSpacing: -0.4,
              height: 1.26,
            ),
          ),
          const SizedBox(height: 16),
          // Classes list
          Expanded(
            child: ListView.builder(
              itemCount: _classes.length,
              itemBuilder: (context, index) {
                final classInfo = _classes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE9ECEF),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      classInfo.className,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${classInfo.totalStudents} sinh viên',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        if (classInfo.schedule != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            classInfo.schedule!,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    onTap: () {
                      // Navigate to class detail
                      // Navigator.pushNamed(context, '/class/detail', arguments: classInfo);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



// Settings Tab based on the provided design screenshot
class _TeacherSettingsTab extends StatefulWidget {
  const _TeacherSettingsTab({Key? key}) : super(key: key);

  @override
  State<_TeacherSettingsTab> createState() => _TeacherSettingsTabState();
}

class _TeacherSettingsTabState extends State<_TeacherSettingsTab> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userResponse = await ApiService().getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        setState(() {
          _userData = userResponse.data!.user;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    
    // Fallback to session data if API fails
    setState(() {
      _userData = UserSession().userData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

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
                      value: _userData?['full_name'] ?? 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      iconColor: Colors.blue,
                      label: 'EMAIL',
                      value: _userData?['email'] ?? 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 16),
                    
                    // Date of birth
                    _buildInfoRow(
                      icon: Icons.favorite_border,
                      iconColor: Colors.red,
                      label: 'NGÀY SINH',
                      value: _userData?['birth_date'] ?? 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 16),
                    
                    // Teacher Code
                    _buildInfoRow(
                      icon: Icons.badge_outlined,
                      iconColor: Colors.green,
                      label: 'MÃ GIẢNG VIÊN',
                      value: _userData?['teacher_code'] ?? 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      iconColor: Colors.blue,
                      label: 'SỐ ĐIỆN THOẠI',
                      value: _userData?['phone'] ?? 'Chưa cập nhật',
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
                        Icon(
                          Icons.logout,
                          size: 22,
                          color: Colors.red[400],
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
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                UserSession().logout();
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/student/login');
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
