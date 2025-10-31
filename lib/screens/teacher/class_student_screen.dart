import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'teacher_class_detail_screen.dart';
import '../../widgets/teacher_bottom_nav.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';

class ClassStudentScreen extends StatefulWidget {
  final int classId;
  final String className;
  final String classCode;
  final int studentCount;

  const ClassStudentScreen({
    Key? key,
    required this.classId,
    required this.className,
    required this.classCode,
    required this.studentCount,
  }) : super(key: key);

  @override
  State<ClassStudentScreen> createState() => _ClassStudentScreenState();
}

class _ClassStudentScreenState extends State<ClassStudentScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<_StudentItem> _students = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    print('DEBUG - Fetching students for classId: ${widget.classId}');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      if (widget.classId <= 0) {
        print('DEBUG - Invalid classId (<= 0), aborting fetch');
        setState(() {
          _error = 'ID lớp không hợp lệ';
        });
        return;
      }

      final baseUrl = ApiService.baseUrl;
      final url = Uri.parse('$baseUrl/classes/${widget.classId}/students?active_only=true');
      
      print('DEBUG - Request URL: $url');
      // Build headers with Authorization if available
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      // Access token is stored in UserSession via ApiService.login
      // Avoid logging full token for security
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }
      print("DEBUG - Authorization header present: ${headers.containsKey('Authorization')}");

      final response = await http.get(url, headers: headers);
      
      print('DEBUG - Response status: ${response.statusCode}');
      print('DEBUG - Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<_StudentItem> loaded = [];
        
        for (var item in data) {
          loaded.add(_StudentItem(
            name: item['student_name'] ?? '',
            studentId: item['student_code'] ?? '',
          ));
        }
        
        print('DEBUG - Loaded ${loaded.length} students');
        
        setState(() {
          _students = loaded;
        });
      } else {
        setState(() {
          _error = 'Lỗi lấy dữ liệu sinh viên';
        });
      }
    } catch (e) {
      print('DEBUG - Error: $e');
      setState(() {
        _error = 'Lỗi kết nối: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<_StudentItem> get filteredStudents {
    if (_searchController.text.isEmpty) {
      return _students;
    }
    final query = _searchController.text.toLowerCase();
    return _students.where((student) =>
        student.name.toLowerCase().contains(query) ||
        student.studentId.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar space
            const SizedBox(height: 8),
            
            // Header with back button and search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Search button
                  GestureDetector(
                    onTap: () {
                      // Toggle search functionality
                      setState(() {});
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Class title
            Center(
              child: Text(
                widget.className,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 32,
                  height: 1.235,
                  letterSpacing: -0.64,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Class info row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Student count
                  Row(
                    children: [
                      const Icon(
                        Icons.group_outlined,
                        size: 20,
                        color: Color(0xFF667085),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.studentCount} sinh viên',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          height: 1.0,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                  // Class code
                  Row(
                    children: [
                      const Icon(
                        Icons.code,
                        size: 24,
                        color: Color(0xFF667085),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.classCode,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          fontSize: 24,
                          height: 0.833,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Students section header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Danh sách sinh viên',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1.235,
                  letterSpacing: -0.36,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Session button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF27C840),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2264E5).withOpacity(0.12),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2264E5),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      // Navigate to class detail screen
                      print('DEBUG - Navigating to TeacherClassDetailScreen with classId: ${widget.classId}, classCode: ${widget.classCode}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherClassDetailScreen(
                            classId: widget.classId,
                            classCode: widget.classCode,
                          ),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        'Buổi học',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.429,
                          letterSpacing: 0.28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Student list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchStudents,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : filteredStudents.isEmpty
                          ? const Center(child: Text('Không có sinh viên nào'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredStudents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final student = filteredStudents[index];
                                return _StudentCard(student: student);
                              },
                            ),
            ),
          ],
        ),
      ),
      // Use shared bottom navigation
      bottomNavigationBar: const TeacherBottomNav(currentIndex: 0),
    );
  }
}

// Student item model
class _StudentItem {
  final String name;
  final String studentId;
  
  const _StudentItem({
    required this.name,
    required this.studentId,
  });
}

// Student card widget
class _StudentCard extends StatelessWidget {
  final _StudentItem student;
  
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEAECF0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student name
          Text(
            student.name,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.556,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 8),
          
          // Student ID row
          Row(
            children: [
              const Icon(
                Icons.list_alt_outlined,
                size: 16,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 4),
              Text(
                student.studentId,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.429,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
