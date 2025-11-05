import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'class_student_screen.dart';
import 'teacher_class_search_screen.dart';
import '../../services/user_session.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final int initialTab;
  
  const TeacherDashboardScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<_ClassItem> _classes = [];
  bool _isLoading = false;
  String? _error;

  // Lấy teacherId từ profile_id trong UserSession
  int? get teacherId {
    final profileId = UserSession().userData?['profile_id'];
    if (profileId is int) return profileId;
    if (profileId is String) return int.tryParse(profileId);
    return null;
  }

  Future<void> _fetchClasses() async {
    if (teacherId == null) {
      setState(() {
        _error = 'Không tìm thấy mã giáo viên';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final baseUrl = ApiService.baseUrl;
      final url = Uri.parse('$baseUrl/classes?teacher_id=$teacherId');

      // Build headers with Authorization if available
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      final response = await http.get(url, headers: headers);
      print('DEBUG - API Response status: ${response.statusCode}');
      print('DEBUG - API Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG - Parsed data: $data');
        
        // API trả về PaginatedResponse với items array
        final List<_ClassItem> loaded = [];
        for (var item in (data['items'] ?? [])) {
          print('DEBUG - Processing item: $item');
          
          // Parse id an toàn
          final rawId = item['id'] ?? item['class_id'];
          print('DEBUG - Raw id value: $rawId (type: ${rawId.runtimeType})');
          
          final int classId = (rawId is int)
              ? rawId
              : (rawId is String ? int.tryParse(rawId) ?? 0 : 0);
          
          final title = item['name'] ?? item['class_name'] ?? '';
          final code = item['code'] ?? item['class_code'] ?? '';
          final studentsCount = item['student_count'] ?? item['students_count'] ?? 0;

          print('DEBUG - Class item parsed -> id=$classId, name=$title, code=$code, student_count=$studentsCount');
          
          loaded.add(_ClassItem(
            id: classId,
            title: title,
            code: code,
            students: studentsCount is int
                ? studentsCount
                : (studentsCount is String ? int.tryParse(studentsCount) ?? 0 : 0),
          ));
        }
        setState(() {
          _classes = loaded;
        });
        print('DEBUG - Loaded ${loaded.length} classes');
      } else {
        setState(() {
          _error = 'Lỗi lấy dữ liệu lớp học';
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

  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    // Gọi API mỗi khi màn hình được load lại
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_classes.isEmpty && !_isLoading) {
        _fetchClasses();
      }
    });
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Danh sách lớp',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.36,
                      height: 1.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 1; // Switch to settings tab
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _currentIndex == 0 ? _buildHomeTab() : _buildSettingsTab(),
      // Simple bottom navigation bar
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF565656).withOpacity(0.25),
              blurRadius: 100,
              offset: const Offset(0, -10),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  color: _currentIndex == 0 
                      ? const Color(0xFF2196F3) 
                      : Colors.black.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _currentIndex == 1 ? Icons.person : Icons.person_outline,
                  color: _currentIndex == 1 
                      ? const Color(0xFF2196F3) 
                      : Colors.black.withOpacity(0.7),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                // Navigate to advanced search screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherClassSearchScreen(),
                  ),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0x142196F3), // #2196F3 @ 8%
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x4D333333)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, size: 24, color: Colors.black54),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tìm kiếm lớp',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.235,
                          letterSpacing: -0.32,
                          color: Color(0xB3333333), // 70%
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // List of classes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _classes.isEmpty
                        ? const Center(child: Text('Không có lớp học nào'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(13, 12, 13, 20),
                            itemCount: _classes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _classes[index];
                              return _ClassCard(
                                item: item,
                                onTap: () {
                                  // Navigate to class detail screen
                                  print('DEBUG - Navigating to class: id=${item.id}, name=${item.title}, code=${item.code}');
                                  
                                  if (item.id == 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Lỗi: ID lớp không hợp lệ')),
                                    );
                                    return;
                                  }
                                  
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClassStudentScreen(
                                        classId: item.id,
                                        className: item.title,
                                        classCode: item.code,
                                        studentCount: item.students,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 40,
        leading: GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = 0; // Go back to home tab
            });
          },
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
                    UserSession().teacherData?.fullName ?? UserSession().username ?? 'Giảng viên',
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
                      value: UserSession().teacherData?.fullName ?? UserSession().username ?? 'Giảng viên',
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      iconColor: Colors.blue,
                      label: 'EMAIL',
                      value: UserSession().teacherData?.email ?? UserSession().username ?? '',
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
                      value: UserSession().teacherData?.phoneNumber ?? 'Chưa cập nhật',
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

// Class item model
class _ClassItem {
  final int id;
  final String title;
  final String code;
  final int students;
  const _ClassItem({required this.id, required this.title, required this.code, required this.students});
}

// Class card widget
class _ClassCard extends StatelessWidget {
  final _ClassItem item;
  final VoidCallback onTap;
  const _ClassCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAECF0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 28 / 18,
                    color: Color(0xFF344054), // Gray/700
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Tag(
                      icon: Icons.list_alt_outlined,
                      label: '${item.students} Sinh viên',
                    ),
                    _Tag(
                      icon: Icons.code,
                      label: item.code,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Tag widget
class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF667085)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 20 / 14,
            color: Color(0xFF667085), // Gray/500
          ),
        ),
      ],
    );
  }
}
