import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import 'student_class_detail_screen.dart';

class ClassSearchScreen extends StatefulWidget {
  const ClassSearchScreen({Key? key}) : super(key: key);

  @override
  State<ClassSearchScreen> createState() => _ClassSearchScreenState();
}

class _ClassSearchScreenState extends State<ClassSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedClassCode;
  String? _selectedTeacher;
  String? _selectedSubject;
  String? _selectedFaculty;
  String? _selectedCohort;

  List<_ClassItem> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final studentId = UserSession().profileId;
    if (studentId == null) {
      setState(() {
        _error = 'Không xác định được student_id. Vui lòng đăng nhập lại.';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final baseUrl = ApiService.baseUrl;
      // Build query params
      final params = <String, String>{'active_only': 'true'};
      
      // Add filters if selected
      // Note: Backend might not support all these filters on student endpoint
      // This is a placeholder - adjust based on actual API capabilities
      
      final url = Uri.parse('$baseUrl/classes/student/$studentId').replace(queryParameters: params);

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      debugPrint('DEBUG - Search URL: $url');
      final resp = await http.get(url, headers: headers);
      debugPrint('DEBUG - Search Status: ${resp.statusCode}');
      debugPrint('DEBUG - Search Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        
        // Client-side filtering based on selections
        final allResults = data.map((e) {
          final m = e as Map<String, dynamic>;
          return _ClassItem(
            id: (m['id'] ?? 0) is int ? m['id'] as int : int.tryParse('${m['id']}') ?? 0,
            title: (m['name'] ?? m['class_name'] ?? 'Chưa rõ').toString(),
            code: (m['code'] ?? m['class_code'] ?? '—').toString(),
            students: (m['student_count'] ?? m['students_count'] ?? 0) as int,
            teacherName: (m['teacher_name'] ?? '').toString(),
            subjectName: (m['subject_name'] ?? '').toString(),
            facultyName: (m['faculty_name'] ?? '').toString(),
            cohortName: (m['cohort_name'] ?? '').toString(),
          );
        }).toList();

        // Apply client-side filters
        final filtered = allResults.where((item) {
          if (_searchController.text.isNotEmpty) {
            final q = _searchController.text.toLowerCase();
            if (!item.title.toLowerCase().contains(q) &&
                !item.code.toLowerCase().contains(q)) {
              return false;
            }
          }
          if (_selectedClassCode != null && item.code != _selectedClassCode) return false;
          if (_selectedTeacher != null && item.teacherName != _selectedTeacher) return false;
          if (_selectedSubject != null && item.subjectName != _selectedSubject) return false;
          if (_selectedFaculty != null && item.facultyName != _selectedFaculty) return false;
          if (_selectedCohort != null && item.cohortName != _selectedCohort) return false;
          return true;
        }).toList();

        setState(() {
          _searchResults = filtered;
        });
      } else {
        setState(() {
          _error = 'Lỗi tìm kiếm (${resp.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: GestureDetector(
                onTap: () {
                  // Focus the text field when tapping the container
                  FocusScope.of(context).requestFocus(FocusNode());
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
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm lớp',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: 16,
                              height: 1.235,
                              letterSpacing: -0.32,
                              color: Color(0xB3333333), // 70%
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChip(
                    label: 'Lọc theo mã lớp',
                    value: _selectedClassCode,
                    onTap: () => _showClassCodePicker(),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChip(
                    label: 'Lọc theo giảng viên',
                    value: _selectedTeacher,
                    onTap: () => _showTeacherPicker(),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChip(
                    label: 'Lọc theo môn học',
                    value: _selectedSubject,
                    onTap: () => _showSubjectPicker(),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChip(
                    label: 'Lọc theo khoa',
                    value: _selectedFaculty,
                    onTap: () => _showFacultyPicker(),
                  ),
                  const SizedBox(height: 8),
                  _buildFilterChip(
                    label: 'Lọc theo khóa',
                    value: _selectedCohort,
                    onTap: () => _showCohortPicker(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _performSearch,
                                  child: const Text('Thử lại'),
                                )
                              ],
                            ),
                          ),
                        )
                      : _searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                'Nhấn nút tìm kiếm để xem kết quả',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];
                                return _ClassCard(
                                  item: item,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentClassDetailScreen(
                                          classCode: item.code,
                                          className: item.title,
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
      ),

      // Floating search button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _performSearch,
        backgroundColor: const Color(0xFF2196F3),
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text(
          'Tìm kiếm',
          style: TextStyle(
            fontFamily: 'Sen',
            fontSize: 13.67,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // Bottom nav
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
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
            IconButton(
              icon: const Icon(Icons.home, color: Color(0xFF2196F3)),
              onPressed: () => Navigator.pop(context),
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: Colors.black.withOpacity(0.7)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF7FE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF687182).withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                value ?? label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black),
          ],
        ),
      ),
    );
  }

  void _showClassCodePicker() {
    // For now, just a simple dialog - you can enhance with actual data
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn mã lớp'),
        content: const Text('Chức năng đang phát triển'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedClassCode = null);
              Navigator.pop(context);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showTeacherPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn giảng viên'),
        content: const Text('Chức năng đang phát triển'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedTeacher = null);
              Navigator.pop(context);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showSubjectPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn môn học'),
        content: const Text('Chức năng đang phát triển'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedSubject = null);
              Navigator.pop(context);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showFacultyPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn khoa'),
        content: const Text('Chức năng đang phát triển'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedFaculty = null);
              Navigator.pop(context);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showCohortPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn khóa'),
        content: const Text('Chức năng đang phát triển'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedCohort = null);
              Navigator.pop(context);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _ClassItem {
  final int id;
  final String title;
  final String code;
  final int students;
  final String teacherName;
  final String subjectName;
  final String facultyName;
  final String cohortName;

  const _ClassItem({
    required this.id,
    required this.title,
    required this.code,
    required this.students,
    this.teacherName = '',
    this.subjectName = '',
    this.facultyName = '',
    this.cohortName = '',
  });
}

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
                    color: Color(0xFF344054),
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
            color: Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}
