import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/session_card.dart';
import '../../widgets/swipe_instructions.dart';
import '../../models/teaching_session.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import '../users/add_session_screen.dart';
import '../users/edit_session_screen.dart';
import 'teacher_session_detail_screen.dart'; // Import teacher screen

class TeacherClassDetailScreen extends StatefulWidget {
  final int classId;
  final String classCode;

  const TeacherClassDetailScreen({
    Key? key,
    required this.classId,
    required this.classCode,
  }) : super(key: key);

  @override
  State<TeacherClassDetailScreen> createState() => _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen> {
  late List<TeachingSession> sessions;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('DEBUG - TeacherClassDetailScreen initState called with classId: ${widget.classId}');
    sessions = [];
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    print('DEBUG - _fetchSessions called');
    print('DEBUG - Fetching sessions for classId: ${widget.classId}');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final baseUrl = ApiService.baseUrl;
      final url = Uri.parse('$baseUrl/classes/${widget.classId}/sessions');
      
      print('DEBUG - Request URL: $url');
      
      // Build headers with Authorization
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
      
      print('DEBUG - Response status: ${response.statusCode}');
      print('DEBUG - Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<TeachingSession> loaded = [];
        
        for (var item in data) {
          // Map API response to TeachingSession model
          // API returns: id, class_id, session_date, start_time, end_time, session_type, qr_code, qr_expired_at, status, created_at, updated_at
          final id = (item['id'] ?? 0).toString();
          final sessionDate = item['session_date'] ?? '';
          final startTime = item['start_time'] ?? '';
          final endTime = item['end_time'] ?? '';
          final status = item['status'] ?? 'Closed';
          
          // Format date and time slot
          String formattedDate = sessionDate;
          try {
            final date = DateTime.parse(sessionDate);
            final weekday = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'][date.weekday % 7];
            formattedDate = '$weekday ${date.day}/${date.month}/${date.year}';
          } catch (_) {}
          
          String timeSlot = '$startTime - $endTime';
          try {
            final start = startTime.split(':');
            final end = endTime.split(':');
            if (start.length >= 2 && end.length >= 2) {
              timeSlot = '${start[0]}:${start[1]} - ${end[0]}:${end[1]}';
            }
          } catch (_) {}
          
          loaded.add(TeachingSession(
            id: id,
            date: formattedDate,
            timeSlot: timeSlot,
            attendanceCount: 0, // Will be fetched separately if needed
            totalStudents: 0,   // Will be fetched separately if needed
            isOpen: status.toLowerCase() == 'open',
          ));
        }
        
        print('DEBUG - Loaded ${loaded.length} sessions');
        
        setState(() {
          sessions = loaded;
        });
      } else {
        setState(() {
          _error = 'Lỗi lấy dữ liệu buổi học';
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
                Text(
                  widget.classCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Session list header and add button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh sách buổi học',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                      letterSpacing: -0.02,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm buổi học'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2264E5),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      // In a real app, this would show a form to add a new session
                      _showAddSessionDialog();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Session list
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
                                onPressed: _fetchSessions,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          color: Colors.white,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sessions.length + 1, // +1 for the instructions
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // First item is the instructions
                                return const SwipeInstructions();
                              }

                              // Adjust index for sessions
                              final sessionIndex = index - 1;
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeacherSessionDetailScreen(
                                        session: sessions[sessionIndex],
                                        classId: widget.classId,
                                      ),
                                    ),
                                  );
                                },
                                child: SessionCard(
                                  session: sessions[sessionIndex],
                                  onEdit: _handleEditSession,
                                  onDelete: _handleDeleteSession,
                                ),
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
              onPressed: () {
                // Navigate back to teacher dashboard (home tab - danh sách lớp)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/teacher/dashboard',
                  arguments: {'initialTab': 0},
                  (route) => false,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, size: 25),
              color: Colors.black.withOpacity(0.7),
              onPressed: () {
                // Navigate back to teacher dashboard (settings tab - cài đặt)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/teacher/dashboard',
                  arguments: {'initialTab': 1},
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSessionDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSessionScreen(
          onSessionAdded: (TeachingSession newSession) {
            setState(() {
              sessions.add(newSession);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm buổi học mới')),
            );
          },
          classId: widget.classId,
        ),
      ),
    );
  }

  void _handleEditSession(TeachingSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSessionScreen(
          session: session,
          onSessionUpdated: (TeachingSession updatedSession) {
            setState(() {
              // Find and replace the updated session
              final index = sessions.indexWhere(
                (s) => s.id == updatedSession.id,
              );
              if (index != -1) {
                sessions[index] = updatedSession;
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật buổi học')),
            );
          },
        ),
      ),
    );
  }

  void _handleDeleteSession(TeachingSession session) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa buổi học này?\n${session.date} ${session.timeSlot}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // Remove the session from the list
                sessions.removeWhere((s) => s.id == session.id);
              });
              Navigator.of(context).pop();

              // Show a snackbar to confirm deletion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa buổi học ${session.date}'),
                  action: SnackBarAction(
                    label: 'Hoàn tác',
                    onPressed: () {
                      // In a real app, you might want to implement undo functionality
                    },
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
