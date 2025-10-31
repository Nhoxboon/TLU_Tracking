import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/teaching_session.dart';
import '../../services/api_service.dart';
import '../../services/user_session.dart';
import 'session_form.dart';

class AddSessionScreen extends StatelessWidget {
  final Function(TeachingSession) onSessionAdded;
  final int classId;

  const AddSessionScreen({Key? key, required this.onSessionAdded, required this.classId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SessionForm(
      title: 'Thêm buổi học',
      onSave: onSessionAdded,
      onSaveRaw: (date, start, end, isOpen) async {
        // Compose API body
        final sessionDate = _formatDate(date); // YYYY-MM-DD
        final startStr = _formatTimeHHMMSS(start);
        final endStr = _formatTimeHHMMSS(end);

        final body = {
          'class_id': classId,
          'session_date': sessionDate,
          'start_time': startStr,
          'end_time': endStr,
          'session_type': 'lecture',
        };

        try {
          final baseUrl = ApiService.baseUrl;
          final url = Uri.parse('$baseUrl/classes/$classId/sessions');
          final headers = <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          };
          final token = UserSession().accessToken;
          final tokenType = UserSession().tokenType ?? 'Bearer';
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = '$tokenType $token';
          }

          // Fire request
          final response = await http.post(url, headers: headers, body: jsonEncode(body));
          debugPrint('DEBUG - Create session status: ${response.statusCode}');
          debugPrint('DEBUG - Create session body: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Build a TeachingSession for UI update
            final teachingSession = TeachingSession(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              date: _formatDateLabel(date),
              timeSlot: _formatTimeSlot(start, end),
              attendanceCount: 0,
              totalStudents: 0,
              isOpen: isOpen,
            );
            onSessionAdded(teachingSession);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã tạo buổi học thành công')),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tạo buổi học thất bại (${response.statusCode})')),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi kết nối: $e')),
            );
          }
        }
      },
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _formatDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String _formatTimeHHMMSS(TimeOfDay time) => '${_two(time.hour)}:${_two(time.minute)}:00';

  static String _formatTimeSlot(TimeOfDay start, TimeOfDay end) {
    String fmt(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';
    return '${fmt(start)} - ${fmt(end)}';
  }

  static String _formatDateLabel(DateTime d) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final wd = days[d.weekday % 7];
    return '$wd ${d.day}/${d.month}/${d.year}';
  }
}
