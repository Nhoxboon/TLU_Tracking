import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/user_session.dart';

class Student {
  final int id;
  final String name;
  final String code;

  Student({
    required this.id,
    required this.name,
    required this.code,
  });
}

class AttendanceRecord {
  final int studentId;
  final String studentName;
  final String studentCode;
  final String status; // present, absent, late, excused

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.status,
  });
}

class StudentSessionDetailScreen extends StatefulWidget {
  const StudentSessionDetailScreen({super.key});

  @override
  State<StudentSessionDetailScreen> createState() => _StudentSessionDetailScreenState();
}

class _StudentSessionDetailScreenState extends State<StudentSessionDetailScreen> {
  List<Student> _allStudents = [];
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;
  int? _classId;
  int? _sessionId;

  @override
  void initState() {
    super.initState();
    
    // Check if returning from successful attendance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      // Get classId and sessionId from arguments
      _classId = args?['classId'] as int?;
      _sessionId = args?['sessionId'] as int?;
      
      if (_classId != null && _sessionId != null) {
        _fetchData();
        
        // If returning from successful attendance, show message and refresh
        if (args?['attendanceSuccess'] == true) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Điểm danh thành công! 🎉'),
                  backgroundColor: Color(0xFF4CAF50),
                  duration: Duration(seconds: 3),
                ),
              );
              // Refresh data after successful attendance
              _fetchData();
            }
          });
        }
      }
    });
  }

  Future<void> _fetchData() async {
    if (_classId == null || _sessionId == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final baseUrl = ApiService.baseUrl;
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      // Fetch all students in class
      final studentsUrl = Uri.parse('$baseUrl/classes/$_classId/students?active_only=true');
      final studentsResponse = await http.get(studentsUrl, headers: headers);

      // Fetch attendance records for session
      final attendanceUrl = Uri.parse('$baseUrl/classes/sessions/$_sessionId/attendance');
      final attendanceResponse = await http.get(attendanceUrl, headers: headers);

      if (studentsResponse.statusCode == 200 && attendanceResponse.statusCode == 200) {
        // Parse all students
        final List<dynamic> studentsData = jsonDecode(studentsResponse.body);
        final List<Student> allStudents = studentsData.map((item) {
          return Student(
            id: item['student_id'] ?? 0,
            name: item['student_name'] ?? '',
            code: item['student_code'] ?? '',
          );
        }).toList();

        // Parse attendance records
        final List<dynamic> attendanceData = jsonDecode(attendanceResponse.body);
        final List<AttendanceRecord> attendanceRecords = attendanceData.map((item) {
          return AttendanceRecord(
            studentId: item['student_id'] ?? 0,
            studentName: item['student_name'] ?? '',
            studentCode: item['student_code'] ?? '',
            status: (item['status'] ?? 'absent').toString().toLowerCase(),
          );
        }).toList();

        setState(() {
          _allStudents = allStudents;
          _attendanceRecords = attendanceRecords;
        });
      } else {
        setState(() {
          _error = 'Lỗi lấy dữ liệu: ${studentsResponse.statusCode} / ${attendanceResponse.statusCode}';
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
    // Get arguments passed from the previous screen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    final String classCode = args?['classCode'] ?? 'CSE';
    final String sessionDate = args?['sessionDate'] ?? 'Thứ 5\n4/9/2025';
    final String sessionTime = args?['sessionTime'] ?? '7AM - 8:15AM';
    final String status = args?['status'] ?? 'Mở';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E1E1E),
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Mobile app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2196F3),
                        letterSpacing: -0.64,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // Balance the back button
                ],
              ),
            ),
            
            // Class code section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.code,
                    size: 24,
                    color: const Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    classCode,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Session date
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                sessionDate,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF344054),
                  height: 1.17,
                ),
              ),
            ),
            
            const SizedBox(height: 28),
            
            // Session time
            Container(
              margin: const EdgeInsets.only(left: 40.0),
              alignment: Alignment.centerLeft,
              child: Text(
                sessionTime,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF344054),
                  height: 1.56,
                ),
              ),
            ),
            
            const SizedBox(height: 22),
            
            // Status row
            Container(
              margin: const EdgeInsets.only(left: 40.0),
              child: Row(
                children: [
                  Text(
                    'Trạng thái:',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    status,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1FB445),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Student attendance list header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Danh sách sinh viên',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                      letterSpacing: -0.02,
                    ),
                  ),
                  const Spacer(),
                  if (_allStudents.isNotEmpty)
                    Text(
                      '${_attendanceRecords.where((a) => a.status == 'present' || a.status == 'late').length}/${_allStudents.length}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF667085),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Student list
            Expanded(
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
                                onPressed: _fetchData,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : _allStudents.isEmpty
                          ? const Center(
                              child: Text(
                                'Chưa có sinh viên trong lớp',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _allStudents.length,
                              itemBuilder: (context, index) {
                                final student = _allStudents[index];
                                // Find attendance record for this student
                                final attendance = _attendanceRecords.firstWhere(
                                  (a) => a.studentId == student.id,
                                  orElse: () => AttendanceRecord(
                                    studentId: student.id,
                                    studentName: student.name,
                                    studentCode: student.code,
                                    status: 'absent',
                                  ),
                                );
                                return _buildStudentCard(student.name, student.code, attendance.status);
                              },
                            ),
            ),
            
            const SizedBox(height: 16),
            
            // Attendance button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Check if session is open before allowing attendance
                  if (status == 'Mở') {
                    // Navigate to QR scanner for attendance
                    Navigator.pushNamed(context, '/qr/scanner');
                  } else {
                    // Show message that session is closed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phiên điểm danh đã đóng'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FB445),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 27,
                    vertical: 6,
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Text(
                      'Điểm danh',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bottom navigation placeholder
            Container(
              height: 59,
              margin: const EdgeInsets.only(bottom: 16),
              width: 370,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF565656).withOpacity(0.25),
                    offset: const Offset(0, -10),
                    blurRadius: 50,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/student/home',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home, color: Colors.grey),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.schedule, color: Color(0xFF2196F3)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/student/settings'),
                    icon: const Icon(Icons.person_outline, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(String name, String studentCode, String attendanceStatus) {
    // Map status từ API sang text hiển thị
    String statusText = 'Vắng mặt';
    Color statusColor = const Color(0xFFFF4444);
    
    if (attendanceStatus == 'present') {
      statusText = 'Có mặt';
      statusColor = const Color(0xFF00FF40);
    } else if (attendanceStatus == 'late') {
      statusText = 'Muộn';
      statusColor = const Color(0xFFFFAA00);
    } else if (attendanceStatus == 'excused') {
      statusText = 'Có phép';
      statusColor = const Color(0xFF00AAFF);
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xFFEAECF0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFEAECF0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Student code
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 4),
                      child: const Icon(
                        Icons.badge_outlined,
                        size: 16,
                        color: Color(0xFF667085),
                      ),
                    ),
                    Text(
                      studentCode,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),

                // Attendance status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}