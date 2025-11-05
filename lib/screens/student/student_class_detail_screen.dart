import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/user_session.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final int classId;
  final String classCode;
  final String className;

  const StudentClassDetailScreen({
    Key? key,
    required this.classId,
    required this.classCode,
    required this.className,
  }) : super(key: key);

  @override
  State<StudentClassDetailScreen> createState() =>
      _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen> {
  final List<_SessionItem> _sessions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSessionsWithAttendance();
  }

  Future<void> _fetchSessionsWithAttendance() async {
    final studentId = UserSession().profileId;
    if (studentId == null) {
      setState(() {
        _error = 'Không xác định được student_id. Vui lòng đăng nhập lại.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final baseUrl = ApiService.baseUrl;
      // 1) Lấy danh sách buổi học của lớp
      final sessionsUrl = Uri.parse('$baseUrl/classes/${widget.classId}/sessions');
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      final token = UserSession().accessToken;
      final tokenType = UserSession().tokenType ?? 'Bearer';
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = '$tokenType $token';
      }

      final resp = await http.get(sessionsUrl, headers: headers);
      if (resp.statusCode != 200) {
        setState(() {
          _error = 'Lỗi tải danh sách buổi học (${resp.statusCode})';
        });
        return;
      }

      final List<dynamic> sessionList = jsonDecode(resp.body);
      final sessionIds = <int>[];
      final baseSessions = <int, Map<String, dynamic>>{}; // id -> session map
      for (final s in sessionList) {
        final m = s as Map<String, dynamic>;
        final sid = (m['id'] ?? 0) is int ? m['id'] as int : int.tryParse('${m['id']}') ?? 0;
        if (sid > 0) {
          sessionIds.add(sid);
          baseSessions[sid] = m;
        }
      }

      if (sessionIds.isEmpty) {
        setState(() {
          _sessions.clear();
        });
        return;
      }

      // 2) Lấy trạng thái điểm danh của SV cho nhiều buổi
      final attUrl = Uri.parse('$baseUrl/classes/sessions/student/$studentId/attendance');
      final attResp = await http.post(
        attUrl,
        headers: headers,
        body: jsonEncode({'session_ids': sessionIds}),
      );

      if (attResp.statusCode != 200) {
        setState(() {
          _error = 'Lỗi tải điểm danh (${attResp.statusCode})';
        });
        return;
      }

      final attData = jsonDecode(attResp.body) as Map<String, dynamic>;
      final List<dynamic> sessionsData = attData['sessions_data'] as List<dynamic>? ?? [];

      // Map: sessionId -> attendanceStatus
      final attendanceBySession = <int, String>{};
      for (final e in sessionsData) {
        final em = e as Map<String, dynamic>;
        final session = em['session'] as Map<String, dynamic>?;
        final sid = (session?['id'] ?? 0) is int ? session!['id'] as int : int.tryParse('${session?['id']}') ?? 0;
        final studentAttendance = em['student_attendance'] as List<dynamic>?;
        if (sid > 0) {
          if (studentAttendance != null && studentAttendance.isNotEmpty) {
            final a = studentAttendance.first as Map<String, dynamic>;
            final status = (a['status'] ?? '').toString().toLowerCase();
            attendanceBySession[sid] = status; // present/late/absent
          } else {
            attendanceBySession[sid] = 'absent';
          }
        }
      }

      // Build UI list
      final loaded = <_SessionItem>[];
      for (final sid in sessionIds) {
        final m = baseSessions[sid] ?? {};
        final sessionDate = (m['session_date'] ?? '').toString();
        final startTime = (m['start_time'] ?? '').toString();
        final endTime = (m['end_time'] ?? '').toString();
        final statusStr = (m['status'] ?? '').toString(); // "Open" / "Closed"

        // Format date: e.g., T2 1/11/2025
        String formattedDate = sessionDate;
        try {
          final date = DateTime.parse(sessionDate);
          final weekday = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'][date.weekday % 7];
          formattedDate = '$weekday ${date.day}/${date.month}/${date.year}';
        } catch (_) {}

        // Format time slot HH:mm - HH:mm
        String timeSlot = '$startTime - $endTime';
        try {
          final start = startTime.split(':');
          final end = endTime.split(':');
          if (start.length >= 2 && end.length >= 2) {
            timeSlot = '${start[0]}:${start[1]} - ${end[0]}:${end[1]}';
          }
        } catch (_) {}

        // Map statuses
        final sessionStatus = statusStr.toLowerCase() == 'open' ? SessionStatus.open : SessionStatus.closed;
        final att = attendanceBySession[sid] ?? 'absent';
        final attendanceStatus = att == 'present'
            ? AttendanceStatus.present
            : att == 'late'
                ? AttendanceStatus.late
                : AttendanceStatus.absent;

        loaded.add(_SessionItem(
          id: sid,
          date: formattedDate,
          time: timeSlot,
          sessionStatus: sessionStatus,
          attendanceStatus: attendanceStatus,
        ));
      }

      setState(() {
        _sessions
          ..clear()
          ..addAll(loaded);
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
              child: _isLoading
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
                                  onPressed: _fetchSessionsWithAttendance,
                                  child: const Text('Thử lại'),
                                )
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
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
                                    'classId': widget.classId,
                                    'classCode': widget.classCode,
                                    'sessionId': session.id,
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
  final int id;
  final String date;
  final String time;
  final SessionStatus sessionStatus;
  final AttendanceStatus attendanceStatus;

  const _SessionItem({
    required this.id,
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
