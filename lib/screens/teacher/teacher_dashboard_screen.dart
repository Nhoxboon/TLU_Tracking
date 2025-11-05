import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'class_student_screen.dart';
import 'teacher_class_search_screen.dart';
import 'teacher_settings_screen.dart';
import 'edit_profile_screen.dart';
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
      // Nếu có nơi nào vẫn set _currentIndex = 1 (kể cả initialTab),
      // điều hướng sang TeacherSettingsScreen thay vì dùng tab cứng
      if (_currentIndex == 1) {
        setState(() {
          _currentIndex = 0;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TeacherSettingsScreen(),
          ),
        );
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
                // Edit profile shortcut
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF2196F3), size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherSettingsScreen(),
                      ),
                    );
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
      body: _buildHomeTab(),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TeacherSettingsScreen(),
                  ),
                );
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
