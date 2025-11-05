import 'package:flutter/material.dart';
// Removed imports for fetching attendance list; student role doesn't load list

// Student list/attendance detail is not shown for student role

class StudentSessionDetailScreen extends StatefulWidget {
  const StudentSessionDetailScreen({super.key});

  @override
  State<StudentSessionDetailScreen> createState() => _StudentSessionDetailScreenState();
}

class _StudentSessionDetailScreenState extends State<StudentSessionDetailScreen> {
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
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get arguments passed from the previous screen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    final String classCode = args?['classCode'] ?? 'CSE';
    final String sessionDate = args?['sessionDate'] ?? 'Thứ 5\n4/9/2025';
    final String sessionTime = args?['sessionTime'] ?? '7AM - 8:15AM';
    final String status = args?['status'] ?? 'Mở';
    final bool isOpen = status == 'Mở';
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
            
            // Student list is hidden for student role
            const Spacer(),
            
            const SizedBox(height: 16),
            
            // State-specific content
            if (!isOpen) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEAECF0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_outline, color: Color(0xFF667085)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Phiên điểm danh đã đóng. Vui lòng liên hệ giảng viên nếu cần hỗ trợ.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Attendance button (enabled when open, disabled when closed)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: isOpen
                    ? () {
                        Navigator.pushNamed(context, '/qr/scanner');
                      }
                    : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) return const Color(0xFFE5E7EB);
                    if (states.contains(MaterialState.pressed)) return const Color(0xFF17923A);
                    return const Color(0xFF1FB445);
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) return const Color(0xFF9CA3AF);
                    return Colors.white;
                  }),
                  overlayColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.pressed)) return const Color(0x331FB445);
                    if (states.contains(MaterialState.hovered)) return const Color(0x1A1FB445);
                    return null;
                  }),
                  elevation: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? 0 : 2),
                  shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.14)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 27, vertical: 6)),
                  minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isOpen ? Colors.white.withOpacity(0.2) : const Color(0xFFF3F4F6),
                      ),
                      child: Icon(
                        isOpen ? Icons.qr_code_scanner : Icons.lock_outline,
                        color: isOpen ? Colors.white : const Color(0xFF9CA3AF),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      isOpen ? 'Điểm danh' : 'Đã đóng',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.48,
                        color: isOpen ? Colors.white : const Color(0xFF9CA3AF),
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

  // No student list card for student role
}