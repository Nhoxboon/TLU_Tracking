import 'package:flutter/material.dart';
import '../../widgets/session_card.dart';
import '../../widgets/swipe_instructions.dart';
import '../../models/teaching_session.dart';
import '../settings_screen.dart';
import '../users/add_session_screen.dart';
import '../users/edit_session_screen.dart';
import 'teacher_session_detail_screen.dart'; // Import teacher screen

class TeacherClassDetailScreen extends StatefulWidget {
  final String classCode;

  const TeacherClassDetailScreen({Key? key, required this.classCode})
    : super(key: key);

  @override
  State<TeacherClassDetailScreen> createState() => _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen> {
  late List<TeachingSession> sessions;

  @override
  void initState() {
    super.initState();
    // In a real app, this would fetch data from a backend service
    sessions = TeachingSession.getMockSessions();
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
              child: Container(
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
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, size: 25),
              color: Colors.black.withOpacity(0.7),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
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
