import 'package:flutter/material.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  @override
  void initState() {
    super.initState();
    
    // Check if returning from successful attendance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args?['attendanceSuccess'] == true) {
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
            
            const SizedBox(height: 71),
            
            // Attendance button
            Container(
              margin: const EdgeInsets.only(right: 55.0),
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
                  minimumSize: const Size(280, 109),
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
                    Text(
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
            
            const Spacer(),
            
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
                    onPressed: () => Navigator.pushReplacementNamed(context, '/student/home'),
                    icon: const Icon(Icons.home, color: Colors.grey),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.schedule, color: Color(0xFF2196F3)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    icon: const Icon(Icons.settings, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}