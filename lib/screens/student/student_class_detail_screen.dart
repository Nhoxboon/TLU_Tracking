import 'package:flutter/material.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final String classCode;
  final String className;

  const StudentClassDetailScreen({
    Key? key,
    required this.classCode,
    required this.className,
  }) : super(key: key);

  @override
  State<StudentClassDetailScreen> createState() =>
      _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  final List<_SessionItem> _sessions = [
    _SessionItem(
      date: 'T5 4/9/2025',
      time: '7AM - 8:15AM',
      sessionStatus: SessionStatus.open,
      attendanceStatus: AttendanceStatus.present,
    ),
    _SessionItem(
      date: 'T5 11/9/2025',
      time: '7AM - 8:15AM',
      sessionStatus: SessionStatus.closed,
      attendanceStatus: AttendanceStatus.present,
    ),
    _SessionItem(
      date: 'T5 18/9/2025',
      time: '7AM - 8:15AM',
      sessionStatus: SessionStatus.closed,
      attendanceStatus: AttendanceStatus.present,
    ),
    _SessionItem(
      date: 'T5 25/9/2025',
      time: '7AM - 8:15AM',
      sessionStatus: SessionStatus.closed,
      attendanceStatus: AttendanceStatus.absent,
    ),
    _SessionItem(
      date: 'T5 2/10/2025',
      time: '7AM - 8:15AM',
      sessionStatus: SessionStatus.closed,
      attendanceStatus: AttendanceStatus.late,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Back button and title row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Class name
                  Text(
                    widget.className,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                      height: 1.235,
                      letterSpacing: -0.64,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Class code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF667085),
                          height: 20 / 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // "Danh sách buổi học" title
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Danh sách buổi học',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                        height: 1.235,
                        letterSpacing: -0.36,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sessions list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                itemCount: _sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return _SessionCard(
                    session: session,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/session/detail',
                        arguments: {
                          'classCode': widget.classCode,
                          'sessionDate': session.date,
                          'sessionTime': session.time,
                          'status': session.sessionStatus == SessionStatus.open ? 'Mở' : 'Đóng',
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Center QR scan button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2196F3),
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.pushNamed(context, '/qr/scanner');
        },
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),

      // Bottom bar
      bottomNavigationBar: BottomAppBar(
        height: 60,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: Colors.white,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home_outlined,
                size: 25,
                color: Colors.black.withOpacity(0.7),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 40), // space for the FAB notch
            IconButton(
              icon: Icon(
                Icons.person_outline,
                size: 25,
                color: Colors.black.withOpacity(0.7),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/student/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum SessionStatus { open, closed }

enum AttendanceStatus { present, absent, late }

class _SessionItem {
  final String date;
  final String time;
  final SessionStatus sessionStatus;
  final AttendanceStatus attendanceStatus;

  const _SessionItem({
    required this.date,
    required this.time,
    required this.sessionStatus,
    required this.attendanceStatus,
  });
}

class _SessionCard extends StatelessWidget {
  final _SessionItem session;
  final VoidCallback? onTap;

  const _SessionCard({required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFEAECF0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAECF0)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
          // Date and time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session.date,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 28 / 18,
                  color: Color(0xFF344054),
                ),
              ),
              Text(
                session.time,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 28 / 18,
                  color: Color(0xFF344054),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Status badges row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusBadge(
                label: session.sessionStatus == SessionStatus.open ? 'Mở' : 'Đóng',
                color: session.sessionStatus == SessionStatus.open
                    ? const Color(0xFF00FF40)
                    : Colors.red,
                textColor: session.sessionStatus == SessionStatus.open
                    ? Colors.black
                    : Colors.white,
              ),
              _StatusBadge(
                label: _getAttendanceLabel(session.attendanceStatus),
                color: _getAttendanceColor(session.attendanceStatus),
                textColor: session.attendanceStatus == AttendanceStatus.late
                    ? Colors.black
                    : (session.attendanceStatus == AttendanceStatus.present
                        ? Colors.black
                        : Colors.white),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAttendanceLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Có mặt';
      case AttendanceStatus.absent:
        return 'Vắng';
      case AttendanceStatus.late:
        return 'Muộn';
    }
  }

  Color _getAttendanceColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF00FF40);
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return const Color(0xFFEEFF00);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(29),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Sen',
          fontSize: 13.666,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
      ),
    );
  }
}
