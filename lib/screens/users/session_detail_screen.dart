import 'package:flutter/material.dart';
import '../../models/teaching_session.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SessionDetailScreen extends StatelessWidget {
  final TeachingSession session;

  const SessionDetailScreen({Key? key, required this.session})
    : super(key: key);

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

            // Attendance list header and QR button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh sách điểm danh',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                      letterSpacing: -0.02,
                    ),
                  ),
                  // QR Code button
                  ElevatedButton.icon(
                    icon: Image.asset(
                      'assets/images/qr_code.png',
                      width: 16,
                      height: 16,
                    ),
                    label: const Text('QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2264E5),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QRCodeScreen(session: session),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Student attendance count
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.people, color: const Color(0xFF667085), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${session.attendanceCount}/${session.totalStudents} Sinh viên',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),

            // Attendance list
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 20, // Using mock data for demonstration
                  itemBuilder: (context, index) {
                    return _buildStudentCard('Nguyễn Sơn', '2251171235');
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

  Widget _buildStudentCard(String name, String studentId) {
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
                    color: const Color(0xFF00FF40),
                    borderRadius: BorderRadius.circular(29),
                  ),
                  child: const Text(
                    'Có mặt',
                    style: TextStyle(
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
                  data:
                      'TLU_ATTENDANCE:${session.id}_${session.date}_${session.timeSlot}',
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
