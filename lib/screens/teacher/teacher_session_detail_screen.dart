import 'package:flutter/material.dart';
import '../../models/teaching_session.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/user_session.dart';

class AttendanceRecord {
  final int id;
  final int studentId;
  final String studentName;
  final String studentCode;
  final String status;
  final DateTime? attendanceTime;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.status,
    this.attendanceTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      studentName: json['student_name'] ?? '',
      studentCode: json['student_code'] ?? '',
      status: json['status'] ?? 'absent',
      attendanceTime: json['attendance_time'] != null 
          ? DateTime.tryParse(json['attendance_time']) 
          : null,
    );
  }
}

class TeacherSessionDetailScreen extends StatefulWidget {
  final TeachingSession session;
  final int classId;

  const TeacherSessionDetailScreen({
    Key? key,
    required this.session,
    required this.classId,
  }) : super(key: key);

  @override
  State<TeacherSessionDetailScreen> createState() => _TeacherSessionDetailScreenState();
}

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

class _TeacherSessionDetailScreenState extends State<TeacherSessionDetailScreen> {
  List<Student> _allStudents = [];
  List<AttendanceRecord> _attendanceList = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
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
      final studentsUrl = Uri.parse('$baseUrl/classes/${widget.classId}/students?active_only=true');
      final studentsResponse = await http.get(studentsUrl, headers: headers);

      // Fetch attendance records for session
      final attendanceUrl = Uri.parse('$baseUrl/classes/sessions/${widget.session.id}/attendance');
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
          return AttendanceRecord.fromJson(item);
        }).toList();

        setState(() {
          _allStudents = allStudents;
          _attendanceList = attendanceRecords;
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Mobile app',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                        letterSpacing: -0.02,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Class code display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.code, color: Color(0xFF8E8E93), size: 24),
                const SizedBox(width: 4),
                const Text(
                  'CSE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Student list header (left aligned)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Danh sách sinh viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2196F3),
                    letterSpacing: -0.02,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // QR Code button (left aligned)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code, size: 20),
                  label: const Text('QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2264E5),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QRCodeScreen(session: widget.session),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Student attendance count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.people, color: const Color(0xFF667085), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _allStudents.isNotEmpty
                        ? '${_attendanceList.where((a) => a.status.toLowerCase() == 'present' || a.status.toLowerCase() == 'late').length}/${_allStudents.length} Sinh viên'
                        : '0/0 Sinh viên',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),

            // Attendance list - show all students with attendance status
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchData,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          color: Colors.white,
                          child: _allStudents.isEmpty
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
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _allStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = _allStudents[index];
                                    // Find attendance record for this student
                                    final attendance = _attendanceList.firstWhere(
                                      (a) => a.studentId == student.id,
                                      orElse: () => AttendanceRecord(
                                        id: 0,
                                        studentId: student.id,
                                        studentName: student.name,
                                        studentCode: student.code,
                                        status: 'absent',
                                      ),
                                    );
                                    return _buildStudentCard(
                                      attendance.studentName,
                                      attendance.studentCode,
                                      attendance.status,
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 100,
              offset: const Offset(0, -10),
            ),
          ],
          backgroundBlendMode: BlendMode.overlay,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 25),
              color: const Color(0xFF2196F3),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, size: 25),
              color: Colors.black.withOpacity(0.7),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(String name, String studentId, String status) {
    // Map status từ API sang text hiển thị
    String statusText = 'Vắng mặt';
    Color statusColor = const Color(0xFFFF4444);
    
    if (status.toLowerCase() == 'present') {
      statusText = 'Có mặt';
      statusColor = const Color(0xFF00FF40);
    } else if (status.toLowerCase() == 'late') {
      statusText = 'Muộn';
      statusColor = const Color(0xFFFFAA00);
    } else if (status.toLowerCase() == 'excused') {
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
        padding: const EdgeInsets.all(10),
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
                // Student ID
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 4),
                      child: const Icon(
                        Icons.list_alt,
                        size: 16,
                        color: Color(0xFF667085),
                      ),
                    ),
                    Text(
                      studentId,
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
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(29),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
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

// QR Code Screen
class QRCodeScreen extends StatelessWidget {
  final TeachingSession session;

  const QRCodeScreen({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Mobile app',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                        letterSpacing: -0.02,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Class code display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.code, color: Color(0xFF8E8E93), size: 24),
                const SizedBox(width: 4),
                const Text(
                  'CSE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // QR Code title
            const Text(
              'Quét để điểm danh',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2196F3),
                letterSpacing: -0.02,
              ),
            ),

            const SizedBox(height: 32),

            // QR Code Image
            Container(
              width: 207,
              height: 217,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                  ),
                ],
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: QrImageView(
                  data: '${session.id}',
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Share button
                Column(
                  children: [
                    Container(
                      width: 68,
                      height: 72,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.share,
                          size: 32,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const Text(
                      'Share',
                      style: TextStyle(
                        fontFamily: 'Itim',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 32),

                // Save button
                Column(
                  children: [
                    Container(
                      width: 68,
                      height: 72,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.save,
                          size: 32,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const Text(
                      'Save',
                      style: TextStyle(
                        fontFamily: 'Itim',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 100,
              offset: const Offset(0, -10),
            ),
          ],
          backgroundBlendMode: BlendMode.overlay,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 25),
              color: const Color(0xFF2196F3),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, size: 25),
              color: Colors.black.withOpacity(0.7),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
